import GLib from "gi://GLib"
import { createState } from "ags"
import { execAsync } from "ags/process"
import { pad } from "../utils"

const BIN = GLib.getenv("SOLTTY_BIN") || "soltty"

const DOT_PALETTE = ["#6c8ea3", "#c58a5a", "#8ba368", "#a3799a", "#6a615a"]
export const NO_PROJECT_COLOR = DOT_PALETTE[4]

const POLL_IDLE_MS = 15000
const POLL_ACTIVE_MS = 2500

const DESC_KEYS = ["description", "desc"]
const PROJECT_KEYS = ["project", "project_name"]
const START_KEYS = ["start_time", "start", "started_at"]
const COLOR_KEYS = ["color", "colour"]

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

let runningEntryId: string | null = null

export const solttyState = {
    connected,
    running,
    startedAt,
    runningDesc,
    runningProject,
    projects,
    recent,
}

function dotColor(idx: number): string {
    return DOT_PALETTE[idx % DOT_PALETTE.length]
}

type Json = Record<string, unknown>

async function runJson(args: string[]): Promise<unknown> {
    try {
        return JSON.parse(await execAsync([BIN, ...args])) as unknown
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
    const o = (data ?? {}) as Json
    return ([o.projects, o.entries, o.data].find(Array.isArray) as Json[] | undefined) ?? []
}

function hhmm(s: string): string {
    const ms = Date.parse(s)
    if (Number.isNaN(ms)) return s.slice(0, 5)
    const d = new Date(ms)
    return `${pad(d.getHours())}:${pad(d.getMinutes())}`
}

function entrySeconds(e: Json): number {
    const n = Number(e.duration ?? e.dur ?? e.elapsed)
    if (Number.isFinite(n) && n > 0) return n
    const start = Date.parse(pickStr(e, START_KEYS))
    const endStr = pickStr(e, ["end_time", "end", "ended_at", "stop"])
    const end = endStr ? Date.parse(endStr) : Date.now()
    return end > start ? Math.floor((end - start) / 1000) : 0
}

function fmtDur(sec: number): string {
    if (!Number.isFinite(sec) || sec <= 0) return "–"
    const h = Math.floor(sec / 3600)
    const m = Math.floor((sec % 3600) / 60)
    if (h > 0) return `${h}h ${pad(m)}m`
    if (m > 0) return `${m}m`
    return "<1m"
}

export async function refreshCurrent(): Promise<void> {
    const data = (await runJson(["current", "--json"])) as Json | null
    if (!data || typeof data.running !== "boolean") {
        setConnected(false)
        return
    }
    setConnected(true)
    const r = data.running
    setRunning(r)
    runningEntryId = r ? pickStr(data, ["id"]) || null : null
    setRunningDesc(r ? pickStr(data, DESC_KEYS) : "")
    setRunningProject(r ? pickStr(data, PROJECT_KEYS) || null : null)
    const ms = r ? Date.parse(pickStr(data, START_KEYS)) : NaN
    setStartedAt(Number.isNaN(ms) ? null : ms)
}

export async function refreshProjects(): Promise<void> {
    const arr = toArray(await runJson(["list", "projects", "--json"]))
    if (!arr.length) return
    setProjects(
        arr.map((p, i) => ({
            id: pickStr(p, ["id", "project_id"]),
            name: pickStr(p, ["name", "project", "title"], "(unnamed)"),
            color: pickStr(p, COLOR_KEYS) || dotColor(i),
            client: pickStr(p, ["client", "client_name", "clientName"]) || null,
        })),
    )
}

export async function refreshRecent(): Promise<void> {
    const arr = toArray(await runJson(["list", "--json", "--limit", "4"]))
    if (!arr.length) return
    const byName = new Map(projects().map((p) => [p.name, p.color]))
    setRecent(
        arr.map((e, i) => {
            const rawId = pickStr(e, ["id", "short_id", "shortId"])
            return {
                id: rawId ? rawId.slice(0, 8) : `e${i}`,
                start: hhmm(pickStr(e, START_KEYS)),
                dur: fmtDur(entrySeconds(e)),
                color: pickStr(e, COLOR_KEYS) || byName.get(pickStr(e, PROJECT_KEYS)) || dotColor(i),
                desc: pickStr(e, DESC_KEYS, "(no description)"),
            }
        }),
    )
}

async function execRefresh(args: string[]): Promise<void> {
    try {
        await execAsync([BIN, ...args])
    } catch {
    } finally {
        await refreshCurrent()
        await refreshRecent()
    }
}

export function startTimer(desc: string, project: string | null): Promise<void> {
    return execRefresh(["start", desc, "--yes", ...(project ? ["--project", project] : [])])
}

export function stopTimer(): Promise<void> {
    return execRefresh(["stop"])
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

async function patchRunning(fields: Record<string, unknown>): Promise<void> {
    const cfg = readSolttyConfig()
    if (!cfg || !runningEntryId) return
    const url = `${cfg.base_url}/organizations/${cfg.workspace_id}/time-entries/${runningEntryId}`
    try {
        await execAsync([
            "curl", "-sS", "-X", "PUT", url,
            "-H", `Authorization: Bearer ${cfg.api_token}`,
            "-H", "Content-Type: application/json",
            "-H", "Accept: application/json",
            "-d", JSON.stringify(fields),
        ])
    } catch {
    }
    refreshCurrent()
}

export async function updateRunningDescription(text: string): Promise<void> {
    if (!running() || text === runningDesc()) return
    await patchRunning({ description: text })
}

export async function updateRunningProject(projectName: string | null): Promise<void> {
    if (!running() || projectName === runningProject()) return
    await patchRunning({ project_id: projects().find((p) => p.name === projectName)?.id ?? null })
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
}

export function setSolttyActive(active: boolean): void {
    pollMs = active ? POLL_ACTIVE_MS : POLL_IDLE_MS
    schedulePoll()
    if (active) {
        refreshProjects()
        refreshRecent()
    }
}
