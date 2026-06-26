import { readFile } from "ags/file"
import { createPoll } from "ags/time"
import { Gtk } from "ags/gtk4"
import { glyph } from "./glyphs"

let prevIdle = 0
let prevTotal = 0

function cpuPct(): number {
    try {
        const line = readFile("/proc/stat").split("\n")[0]
        const values = line.split(/\s+/).slice(1).map(Number)
        const idle = values[3] + values[4]
        const total = values.reduce((a, b) => a + b, 0)
        const dIdle = idle - prevIdle
        const dTotal = total - prevTotal
        prevIdle = idle
        prevTotal = total
        if (dTotal === 0) return 0
        return Math.round((1 - dIdle / dTotal) * 100)
    } catch {
        return 0
    }
}

function ramPct(): number {
    try {
        const m = readFile("/proc/meminfo")
        const get = (k: string) => Number(m.match(new RegExp(`${k}:\\s+(\\d+)`))?.[1] ?? 0)
        const total = get("MemTotal")
        const avail = get("MemAvailable")
        if (!total) return 0
        return Math.round((1 - avail / total) * 100)
    } catch {
        return 0
    }
}

let tempPath: string | null | undefined = undefined

function resolveTempPath(): string | null {
    const prefs = ["x86_pkg_temp", "coretemp", "k10temp", "cpu", "acpitz"]
    const found: Record<string, string> = {}
    for (let i = 0; i < 12; i++) {
        try {
            const type = readFile(`/sys/class/thermal/thermal_zone${i}/type`).trim()
            found[type] = `/sys/class/thermal/thermal_zone${i}/temp`
        } catch {
            continue
        }
    }
    for (const p of prefs) {
        for (const k of Object.keys(found)) {
            if (k.toLowerCase().includes(p)) return found[k]
        }
    }
    const keys = Object.keys(found)
    return keys.length ? found[keys[0]] : null
}

function tempC(): number | null {
    if (tempPath === undefined) tempPath = resolveTempPath()
    if (!tempPath) return null
    try {
        return Math.round(Number(readFile(tempPath)) / 1000)
    } catch {
        return null
    }
}

type Stats = { cpu: number; ram: number; temp: number | null }

const stats = createPoll<Stats>({ cpu: 0, ram: 0, temp: null }, 2000, () => ({
    cpu: cpuPct(),
    ram: ramPct(),
    temp: tempC(),
}))

export default function SystemStats() {
    const cpu = stats((s) => s.cpu)
    const ram = stats((s) => s.ram)
    const temp = stats((s) => s.temp)
    const hasTemp = stats((s) => s.temp !== null)

    return (
        <box class="system-stats">
            <box class="stat stat-cpu">
                <label class="stat-icon" label={glyph.cpu} />
                <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER}>
                    <label class="stat-value" halign={Gtk.Align.START} label={cpu((v) => `${v}%`)} />
                    <Gtk.LevelBar class="stat-bar" value={cpu((v) => v / 100)} />
                </box>
            </box>
            <box class="stat stat-ram">
                <label class="stat-icon" label={glyph.memory} />
                <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER}>
                    <label class="stat-value" halign={Gtk.Align.START} label={ram((v) => `${v}%`)} />
                    <Gtk.LevelBar class="stat-bar" value={ram((v) => v / 100)} />
                </box>
            </box>
            <box class="stat stat-temp" visible={hasTemp}>
                <label class="stat-icon stat-temp-icon" label={glyph.thermometer} />
                <label class="stat-value" label={temp((v) => (v !== null ? `${v}°` : ""))} />
            </box>
        </box>
    )
}
