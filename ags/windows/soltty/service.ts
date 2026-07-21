import GLib from "gi://GLib"
import { createState } from "ags"
import { execAsync } from "ags/process"

const BIN = GLib.getenv("SOLTTY_BIN") || "soltty"

const DOT_PALETTE = ["#6c8ea3", "#c58a5a", "#8ba368", "#a3799a", "#6a615a"]

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

const [connected, setConnected] = createState(false)
const [running, setRunning] = createState(false)
const [startedAt, setStartedAt] = createState<number | null>(null)
const [runningDesc, setRunningDesc] = createState("")
const [runningProject, setRunningProject] = createState<string | null>(null)
const [projects, setProjects] = createState<Project[]>([])
const [recent, setRecent] = createState<RecentEntry[]>([])
const [tick, setTick] = createState(0)

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

function dotColor(idx: number): string {
    return DOT_PALETTE[idx % DOT_PALETTE.length]
}

type Json = Record<string, unknown>

function run(args: string[]): Promise<string> {
    return execAsync([BIN, ...args])
}

function parseJson(out: string): unknown {
    try {
        return JSON.parse(out) as unknown
    } catch {
        return null
    }
}

function pickStr(obj: Json | null, keys: string[], fallback = ""): string {
    for (const k of keys) {
        const v = obj?.[k]
        if (typeof v === "string" && v.length) return v
    }
    return fallback
}

function toArray(data: unknown): Json[] {
    if (Array.isArray(data)) return data as Json[]
    const o = data as Json | null
    for (const k of ["projects", "entries", "data"]) {
        const v = o?.[k]
        if (Array.isArray(v)) return v as Json[]
    }
    return []
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

function entrySeconds(e: Json): number {
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

export async function refreshCurrent(): Promise<void> {
    try {
        const data = parseJson(await run(["current", "--json"])) as Json | null
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
        setConnected(false)
    }
}

export async function refreshProjects(): Promise<void> {
    try {
        const arr = toArray(parseJson(await run(["list", "projects", "--json"])))
        setProjects(
            arr.map((p, i) => ({
                id: pickStr(p, ["id", "project_id"]),
                name: pickStr(p, ["name", "project", "title"], "(unnamed)"),
                color: pickStr(p, ["color", "colour"]) || dotColor(i),
                client: pickStr(p, ["client", "client_name", "clientName"]) || null,
            })),
        )
    } catch {
    }
}

export async function refreshRecent(): Promise<void> {
    try {
        const arr = toArray(parseJson(await run(["list", "--json", "--limit", "4"])))
        const byName = new Map(projects().map((p) => [p.name, p.color]))
        setRecent(
            arr.map((e, i) => {
                const proj = pickStr(e, ["project", "project_name"])
                const rawId = pickStr(e, ["id", "short_id", "shortId"])
                return {
                    id: rawId ? rawId.slice(0, 8) : `e${i}`,
                    start: hhmm(pickStr(e, ["start_time", "start", "started_at"])),
                    dur: fmtDur(entrySeconds(e)),
                    color: pickStr(e, ["color", "colour"]) || byName.get(proj) || dotColor(i),
                    desc: pickStr(e, ["description", "desc"], "(no description)"),
                }
            }),
        )
    } catch {
    }
}

export async function startTimer(desc: string, project: string | null): Promise<void> {
    const args = ["start", desc, "--yes"]
    if (project) args.push("--project", project)
    try {
        await run(args)
    } catch {
    } finally {
        await refreshCurrent()
        await refreshRecent()
    }
}

export async function stopTimer(): Promise<void> {
    try {
        await run(["stop"])
    } catch {
    } finally {
        await refreshCurrent()
        await refreshRecent()
    }
}

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
            const c = JSON.parse(new TextDecoder().decode(bytes)) as Json
            if (c?.api_token && c?.base_url && c?.workspace_id) {
                return {
                    api_token: String(c.api_token),
                    base_url: String(c.base_url).replace(/\/+$/, ""),
                    workspace_id: String(c.workspace_id),
                }
            }
        } catch {
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

export async function updateRunningDescription(text: string): Promise<void> {
    if (!running() || text === runningDesc()) return
    try {
        await putEntry({ description: text })
    } catch {
    }
    refreshCurrent()
}

export async function updateRunningProject(projectName: string | null): Promise<void> {
    if (!running() || projectName === runningProject()) return
    const pid = projectName
        ? projects().find((p) => p.name === projectName)?.id ?? null
        : null
    try {
        await putEntry({ project_id: pid })
    } catch {
    }
    refreshCurrent()
}

let pollId = 0
let pollMs = POLL_IDLE_MS

function schedulePoll(): void {
    if (pollId) GLib.source_remove(pollId)
    pollId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, pollMs, () => {
        refreshCurrent()
        return GLib.SOURCE_CONTINUE
    })
}

export function initSolttyService(): void {
    refreshCurrent()
    schedulePoll()
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, () => {
        if (running()) setTick(tick() + 1)
        return GLib.SOURCE_CONTINUE
    })
}

export function setSolttyActive(active: boolean): void {
    pollMs = active ? POLL_ACTIVE_MS : POLL_IDLE_MS
    schedulePoll()
    if (active) {
        setTick(tick() + 1)
        refreshProjects()
        refreshRecent()
    }
}
