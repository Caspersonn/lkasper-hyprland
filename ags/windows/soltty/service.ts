import GLib from "gi://GLib"
import { createState } from "ags"
import { execAsync } from "ags/process"

// The soltty binary. The Nix wrapper injects an absolute path via SOLTTY_BIN
// (the systemd user service has a stripped PATH); "soltty" is the dev fallback.
const BIN = GLib.getenv("SOLTTY_BIN") || "soltty"

// Fallback dot colors (design tokens) when soltty reports no project color.
const DOT_PALETTE = ["#6c8ea3", "#c58a5a", "#8ba368", "#a3799a", "#6a615a"]

// Poll cadence: slow in the background (keeps the bar dot fresh), fast while the
// overlay is open. Elapsed is ticked locally every second in between polls.
const POLL_IDLE_MS = 15000
const POLL_ACTIVE_MS = 2500

export interface Project {
    id: string
    name: string
    color: string
    client: string | null
}

export interface RecentEntry {
    id: string
    start: string
    dur: string
    color: string
    desc: string
}

// ---- reactive state -------------------------------------------------------

const [connected, setConnected] = createState(false)
const [running, setRunning] = createState(false)
// Wall-clock epoch (ms) the running entry started, or null. The displayed
// HH:MM:SS is derived from this + `tick`, so it stays smooth and correct even
// if the timer was started from another machine.
const [startedAt, setStartedAt] = createState<number | null>(null)
const [runningDesc, setRunningDesc] = createState("")
const [runningProject, setRunningProject] = createState<string | null>(null)
const [projects, setProjects] = createState<Project[]>([])
const [recent, setRecent] = createState<RecentEntry[]>([])
const [tick, setTick] = createState(0)

// Running entry id, for direct Solidtime API edits (not reactive UI state).
let runningEntryId: string | null = null

export const solttyState = {
    connected,
    running,
    startedAt,
    runningDesc,
    runningProject,
    projects,
    recent,
    tick,
}

export function dotColor(name: string, idx: number): string {
    return DOT_PALETTE[idx % DOT_PALETTE.length]
}

// ---- soltty invocation + parsing ------------------------------------------

function run(args: string[]): Promise<string> {
    return execAsync([BIN, ...args])
}

function parseJson(out: string): any {
    try {
        return JSON.parse(out)
    } catch {
        return null
    }
}

// First non-empty string value among candidate keys (soltty's exact JSON key
// casing isn't documented for list output, so we accept common variants).
function pickStr(obj: any, keys: string[], fallback = ""): string {
    for (const k of keys) {
        const v = obj?.[k]
        if (typeof v === "string" && v.length) return v
    }
    return fallback
}

function toArray(data: any): any[] {
    if (Array.isArray(data)) return data
    return data?.projects ?? data?.entries ?? data?.data ?? []
}

function hhmm(s: string): string {
    if (!s) return ""
    const ms = Date.parse(s)
    if (!Number.isNaN(ms)) {
        const d = new Date(ms)
        return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`
    }
    return s.slice(0, 5)
}

// Duration in seconds for a list entry. soltty reports duration=0 (end=null)
// for the still-running entry, so fall back to start->end, or start->now while
// it's still running, so every recent row shows a real duration.
function entrySeconds(e: any): number {
    const raw = e?.duration ?? e?.dur ?? e?.elapsed
    if (typeof raw === "number" && raw > 0) return raw
    if (typeof raw === "string") {
        const n = Number(raw)
        if (Number.isFinite(n) && n > 0) return n
    }
    const start = Date.parse(pickStr(e, ["start_time", "start", "started_at"]))
    if (Number.isNaN(start)) return 0
    const endStr = pickStr(e, ["end_time", "end", "ended_at", "stop"])
    const end = endStr ? Date.parse(endStr) : Date.now()
    if (Number.isNaN(end) || end <= start) return 0
    return Math.floor((end - start) / 1000)
}

function fmtDur(sec: number): string {
    if (!Number.isFinite(sec) || sec <= 0) return "–"
    const h = Math.floor(sec / 3600)
    const m = Math.floor((sec % 3600) / 60)
    if (h > 0) return `${h}h ${String(m).padStart(2, "0")}m`
    if (m > 0) return `${m}m`
    return "<1m"
}

// ---- refreshers -----------------------------------------------------------

export async function refreshCurrent(): Promise<void> {
    try {
        const data = parseJson(await run(["current", "--json"]))
        // soltty exits 0 even when unconfigured or erroring (message goes to
        // stderr / non-JSON stdout), so a valid `running` boolean — not the exit
        // code — is the real connectivity signal. On invalid output, mark
        // disconnected but DON'T wipe a known-good running timer: that caused the
        // clock to flicker to 00:00:00 on open. The next good poll corrects it.
        if (!data || typeof data.running !== "boolean") {
            setConnected(false)
            return
        }
        setConnected(true)
        if (data.running) {
            setRunning(true)
            runningEntryId = pickStr(data, ["id"]) || null
            setRunningDesc(pickStr(data, ["description", "desc"]))
            setRunningProject(pickStr(data, ["project", "project_name"]) || null)
            const iso = pickStr(data, ["start", "started_at"])
            const ms = iso ? Date.parse(iso) : NaN
            setStartedAt(Number.isNaN(ms) ? null : ms)
        } else {
            setRunning(false)
            runningEntryId = null
            setStartedAt(null)
            setRunningDesc("")
            setRunningProject(null)
        }
    } catch {
        // Transient failure: keep the last-known timer state, just flag offline.
        setConnected(false)
    }
}

export async function refreshProjects(): Promise<void> {
    try {
        const arr = toArray(parseJson(await run(["list", "projects", "--json"])))
        setProjects(
            arr.map((p: any, i: number) => {
                const name = pickStr(p, ["name", "project", "title"], "(unnamed)")
                return {
                    id: pickStr(p, ["id", "project_id"]),
                    name,
                    color: pickStr(p, ["color", "colour"]) || dotColor(name, i),
                    client: pickStr(p, ["client", "client_name", "clientName"]) || null,
                }
            }),
        )
    } catch {
        // Keep the previous list; connection state is owned by refreshCurrent.
    }
}

export async function refreshRecent(): Promise<void> {
    try {
        const arr = toArray(parseJson(await run(["list", "--json", "--limit", "4"])))
        const byName = new Map(projects().map((p) => [p.name, p.color]))
        setRecent(
            arr.map((e: any, i: number) => {
                const proj = pickStr(e, ["project", "project_name"])
                const rawId = pickStr(e, ["id", "short_id", "shortId"])
                return {
                    // Non-empty + unique: <For> dedupes rows by id.
                    id: rawId ? rawId.slice(0, 8) : `e${i}`,
                    start: hhmm(pickStr(e, ["start_time", "start", "started_at"])),
                    dur: fmtDur(entrySeconds(e)),
                    color: pickStr(e, ["color", "colour"]) || byName.get(proj) || dotColor(proj, i),
                    desc: pickStr(e, ["description", "desc"], "(no description)"),
                }
            }),
        )
    } catch {
        // Keep the previous list.
    }
}

// ---- actions --------------------------------------------------------------

// Start stops any running timer first (--yes skips soltty's confirm prompt),
// giving a single continuous timeline.
export async function startTimer(desc: string, project: string | null): Promise<void> {
    const args = ["start", desc, "--yes"]
    if (project) args.push("--project", project)
    try {
        await run(args)
    } catch {
        // Surface via connection state on the follow-up refresh.
    } finally {
        await refreshCurrent()
        await refreshRecent()
    }
}

export async function stopTimer(): Promise<void> {
    try {
        await run(["stop"])
    } catch {
        // Ignored; refresh reflects the real state.
    } finally {
        await refreshCurrent()
        await refreshRecent()
    }
}

// ---- live edits to the running entry --------------------------------------
// soltty has no update command, so we PATCH the running entry directly against
// the Solidtime API (mirroring soltty's own `stop`, which PUTs a partial body),
// reading auth from soltty's config.json.

interface SolttyConfig {
    api_token: string
    base_url: string
    workspace_id: string
}

function readSolttyConfig(): SolttyConfig | null {
    const home = GLib.get_home_dir()
    const candidates = [
        `${home}/.config/soltty/config.json`,
        `${home}/.config/solidtime/config.json`,
        `${home}/.solidtime/config.json`,
    ]
    for (const path of candidates) {
        try {
            const [ok, bytes] = GLib.file_get_contents(path)
            if (!ok) continue
            const c = JSON.parse(new TextDecoder().decode(bytes))
            if (c?.api_token && c?.base_url && c?.workspace_id) {
                return {
                    api_token: String(c.api_token),
                    base_url: String(c.base_url).replace(/\/+$/, ""),
                    workspace_id: String(c.workspace_id),
                }
            }
        } catch {
            // try the next candidate
        }
    }
    return null
}

async function putEntry(fields: Record<string, unknown>): Promise<void> {
    const cfg = readSolttyConfig()
    if (!cfg || !runningEntryId) return
    const url = `${cfg.base_url}/organizations/${cfg.workspace_id}/time-entries/${runningEntryId}`
    await execAsync([
        "curl", "-sS", "-X", "PUT", url,
        "-H", `Authorization: Bearer ${cfg.api_token}`,
        "-H", "Content-Type: application/json",
        "-H", "Accept: application/json",
        "-d", JSON.stringify(fields),
    ])
}

// Update the running entry's description in place (no-op if idle/unchanged).
export async function updateRunningDescription(text: string): Promise<void> {
    if (!running() || text === runningDesc()) return
    try {
        await putEntry({ description: text })
    } catch {
        // Leave state; next poll reconciles.
    }
    refreshCurrent()
}

// Update the running entry's project in place (no-op if idle/unchanged).
export async function updateRunningProject(projectName: string | null): Promise<void> {
    if (!running() || projectName === runningProject()) return
    const pid = projectName
        ? projects().find((p) => p.name === projectName)?.id ?? null
        : null
    try {
        await putEntry({ project_id: pid })
    } catch {
        // Leave state; next poll reconciles.
    }
    refreshCurrent()
}

// ---- polling / ticking ----------------------------------------------------

let pollId = 0
let pollMs = POLL_IDLE_MS

function schedulePoll(): void {
    if (pollId) GLib.source_remove(pollId)
    pollId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, pollMs, () => {
        refreshCurrent()
        return GLib.SOURCE_CONTINUE
    })
}

// Called once from app.ts main(): initial state + slow background poll.
export function initSolttyService(): void {
    refreshCurrent()
    schedulePoll()
    // Permanent 1s tick drives the live elapsed clock everywhere (bar + overlay)
    // even while the overlay is closed; only bumps while a timer is running.
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, () => {
        if (running()) setTick(tick() + 1)
        return GLib.SOURCE_CONTINUE
    })
}

// Overlay open/close: fast poll + 1s elapsed tick while active; slow when idle.
export function setSolttyActive(active: boolean): void {
    pollMs = active ? POLL_ACTIVE_MS : POLL_IDLE_MS
    schedulePoll()
    if (active) {
        // Recompute elapsed immediately from the last-known start (avoids a
        // brief 00:00:00 before the next tick); refreshCurrent is driven by
        // toggleSoltty + the fast poll. The 1s tick runs permanently (init).
        setTick(tick() + 1)
        refreshProjects()
        refreshRecent()
    }
}
