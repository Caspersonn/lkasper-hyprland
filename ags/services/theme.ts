import { readFile, writeFile } from "ags/file"
import { exec } from "ags/process"
import { createState } from "ags"
import App from "ags/gtk4/app"
import GLib from "gi://GLib"
import Gio from "gi://Gio"

const HOME = GLib.get_home_dir()
const THEMES_DIR = `${HOME}/.local/share/lkasper-hyprland/themes`
const PERSIST_DIR = `${HOME}/.config/lkasper-hyprland/current`
const PERSIST_FILE = `${PERSIST_DIR}/theme.name`
const WALLPAPER_FILE = `${PERSIST_DIR}/wallpaper`

interface Palette {
    base00: string
    base01: string
    base02: string
    base03: string
    base04: string
    base05: string
    base06: string
    base07: string
    base08: string
    base09: string
    base0A: string
    base0B: string
    base0C: string
    base0D: string
    base0E: string
    base0F: string
}

const [currentTheme, setCurrentTheme] = createState("catppuccin")

function getThemeList(): string[] {
    try {
        const dir = GLib.Dir.open(THEMES_DIR, 0)
        const names: string[] = []
        let name: string | null
        while ((name = dir.read_name()) !== null) {
            const colorsPath = `${THEMES_DIR}/${name}/colors.json`
            if (GLib.file_test(colorsPath, GLib.FileTest.EXISTS)) {
                names.push(name)
            }
        }
        return names.sort()
    } catch {
        return []
    }
}

function readPalette(name: string): Palette | null {
    const path = `${THEMES_DIR}/${name}/colors.json`
    try {
        const content = readFile(path)
        return JSON.parse(content) as Palette
    } catch {
        console.warn(`[theme] Failed to read palette for "${name}"`)
        return null
    }
}

function generateGtkCss(p: Palette): string {
    const bg = `#${p.base00}`
    const fg = `#${p.base05}`
    const fgDim = `#${p.base04}`
    const surface0 = `#${p.base02}`
    const green = `#${p.base0B}`
    const yellow = `#${p.base0A}`
    const red = `#${p.base08}`
    const accent = `#${p.base0C}`

    return `
window.bar {
    background-color: transparent;
    font-size: 14px;
    font-weight: 500;
}

window.bar button {
    min-height: 0;
    min-width: 0;
    padding: 0;
    background: none;
    border: none;
    box-shadow: none;
}

window.bar image {
    -gtk-icon-size: 16px;
}

.pill {
    background-color: ${bg};
    border-radius: 999px;
    padding: 8px 12px;
    color: ${fg};
}

.left-pill {
    margin-right: 8px;
}

.center-pill {
    margin-left: 8px;
    margin-right: 8px;
}

.right-pill {
    margin-left: 8px;
}

.workspace-dot {
    min-width: 8px;
    min-height: 8px;
    border-radius: 999px;
    margin: 0 2px;
    transition: min-width 200ms ease;
}

.workspace-dot.active {
    min-width: 20px;
    min-height: 10px;
    background-color: ${accent};
    border: none;
}

.workspace-dot.occupied {
    background-color: transparent;
    border: 2px solid alpha(${fg}, 0.5);
}

.client-button {
    padding: 2px;
    border-radius: 999px;
}

.client-button image {
    -gtk-icon-size: 20px;
}

.clients-separator {
    border-left: 1px solid alpha(${fg}, 0.12);
    padding-left: 6px;
    margin-left: 6px;
}

.clock {
    font-weight: 700;
}

.media-entry {
    margin-left: 0;
}

.media-icon {
    -gtk-icon-size: 16px;
    margin-right: 6px;
}

.media-label {
    color: ${fg};
}

.separator {
    border-left: 1px solid alpha(${fg}, 0.12);
    padding-left: 6px;
    margin-left: 6px;
}

.module-icon {
    font-size: 14px;
    min-width: 16px;
}

.module-text {
    font-weight: 700;
}

.cpu-icon {
    -gtk-icon-size: 14px;
    margin-left: 4px;
}

.battery.charging {
    color: ${green};
}

.battery.warning {
    color: ${yellow};
}

.battery.critical {
    color: ${red};
}

.volume.muted {
    color: ${fgDim};
}

.bluetooth.disabled {
    color: ${fgDim};
}

.wifi.disconnected {
    color: ${fgDim};
}

.notification-bell {
    font-size: 14px;
}

tooltip {
    background-color: ${surface0};
    color: ${fg};
    border-radius: 8px;
    padding: 6px 10px;
    border: 1px solid alpha(${fg}, 0.08);
}
`
}

function ensureDir(path: string): void {
    if (!GLib.file_test(path, GLib.FileTest.IS_DIR)) {
        GLib.mkdir_with_parents(path, 0o755)
    }
}

function writeHyprlandTheme(p: Palette): void {
    const content = `general {
  col.active_border = rgba(${p.base0D}aa)
  col.inactive_border = rgba(${p.base09}aa)
}

group {
  col.border_active = rgba(${p.base0D}aa)
  col.border_inactive = rgba(${p.base09}aa)
}
`
    ensureDir(`${HOME}/.config/hypr`)
    writeFile(`${HOME}/.config/hypr/theme.conf`, content)
    try {
        exec("hyprctl reload")
    } catch { }
}

function writeGhosttyTheme(p: Palette): void {
    const content = `background = #${p.base00}
foreground = #${p.base05}
selection-background = #${p.base02}
selection-foreground = #${p.base00}
palette = 0=#${p.base00}
palette = 1=#${p.base08}
palette = 2=#${p.base0B}
palette = 3=#${p.base0A}
palette = 4=#${p.base0D}
palette = 5=#${p.base0E}
palette = 6=#${p.base0C}
palette = 7=#${p.base05}
palette = 8=#${p.base03}
palette = 9=#${p.base08}
palette = 10=#${p.base0B}
palette = 11=#${p.base0A}
palette = 12=#${p.base0D}
palette = 13=#${p.base0E}
palette = 14=#${p.base0C}
palette = 15=#${p.base07}
palette = 16=#${p.base09}
palette = 17=#${p.base0F}
palette = 18=#${p.base01}
palette = 19=#${p.base02}
palette = 20=#${p.base04}
palette = 21=#${p.base06}
`
    ensureDir(`${HOME}/.config/ghostty/themes`)
    writeFile(`${HOME}/.config/ghostty/themes/lkh-runtime`, content)
    try {
        exec("bash -c 'kill -SIGUSR1 $(pgrep -x ghostty) 2>/dev/null || true'")
    } catch { }
}

function writeBtopTheme(p: Palette): void {
    const content = `theme[main_fg]="${p.base05}"
theme[title]="${p.base05}"
theme[hi_fg]="${p.base0D}"
theme[selected_bg]="${p.base01}"
theme[selected_fg]="${p.base05}"
theme[inactive_fg]="${p.base04}"
theme[proc_misc]="${p.base0D}"
theme[cpu_box]="${p.base0B}"
theme[mem_box]="${p.base09}"
theme[net_box]="${p.base0E}"
theme[proc_box]="${p.base0C}"
theme[div_line]="${p.base04}"
theme[temp_start]="${p.base0B}"
theme[temp_mid]="${p.base0A}"
theme[temp_end]="${p.base08}"
theme[cpu_start]="${p.base0B}"
theme[cpu_mid]="${p.base0A}"
theme[cpu_end]="${p.base08}"
theme[free_start]="${p.base0B}"
theme[cached_start]="${p.base0A}"
theme[available_start]="${p.base09}"
theme[used_start]="${p.base08}"
theme[download_start]="${p.base0E}"
theme[download_mid]="${p.base0D}"
theme[download_end]="${p.base0C}"
theme[upload_start]="${p.base0E}"
theme[upload_mid]="${p.base0D}"
theme[upload_end]="${p.base0C}"
`
    ensureDir(`${HOME}/.config/btop/themes`)
    writeFile(`${HOME}/.config/btop/themes/lkh-runtime.theme`, content)
}

function writeStarshipConfig(p: Palette): void {
    const content = `add_newline = false
format = "$directory$git_branch$git_status$character"

[directory]
style = "bold #${p.base0D}"
truncation_length = 4

[git_branch]
style = "bold #${p.base05}"

[git_status]
style = "#${p.base05}"

[character]
success_symbol = "[>](bold #${p.base0D})"
error_symbol = "[>](bold #${p.base0D})"
`
    writeFile(`${HOME}/.config/starship.toml`, content)
}

function hyprpaperIpc(cmd: string): string {
    const sig = GLib.getenv("HYPRLAND_INSTANCE_SIGNATURE")
    if (!sig) return "error: no HYPRLAND_INSTANCE_SIGNATURE"
    const socketPath = `${GLib.get_user_runtime_dir()}/hypr/${sig}/.hyprpaper.sock`
    const address = Gio.UnixSocketAddress.new(socketPath)
    const client = new Gio.SocketClient()
    const conn = client.connect(address, null)
    const data = new Uint8Array(Array.from(cmd).map(c => c.charCodeAt(0)))
    conn.get_output_stream().write(data, null)
    conn.get_socket().shutdown(false, true)
    const bytes = conn.get_input_stream().read_bytes(4096, null)
    conn.close(null)
    const arr = bytes.get_data()
    if (!arr || arr.length === 0) return ""
    return String.fromCharCode(...arr).trim()
}

function switchWallpaper(name: string): void {
    const bgDir = `${THEMES_DIR}/${name}/backgrounds`
    if (!GLib.file_test(bgDir, GLib.FileTest.IS_DIR)) return

    try {
        const dir = GLib.Dir.open(bgDir, 0)
        const files: string[] = []
        let fname: string | null
        while ((fname = dir.read_name()) !== null) {
            files.push(fname)
        }
        if (files.length === 0) return

        files.sort()

        let currentWallpaper = ""
        try { currentWallpaper = readFile(WALLPAPER_FILE).trim() } catch {}

        if (currentWallpaper.startsWith(bgDir + "/")) {
            return
        }

        const wallpaperPath = `${bgDir}/${files[0]}`

        const preloadResult = hyprpaperIpc(`preload ${wallpaperPath}`)
        if (preloadResult !== "ok") {
            console.warn(`[theme] Wallpaper preload failed: ${preloadResult}`)
        }

        const wallpaperResult = hyprpaperIpc(`wallpaper ,${wallpaperPath}`)
        if (wallpaperResult !== "ok") {
            console.warn(`[theme] Wallpaper set failed: ${wallpaperResult}`)
        }

        ensureDir(PERSIST_DIR)
        writeFile(WALLPAPER_FILE, wallpaperPath)
    } catch (e) {
        console.warn(`[theme] Failed to switch wallpaper for "${name}": ${e}`)
    }
}

function nextWallpaper(): boolean {
    const name = currentTheme()
    const bgDir = `${THEMES_DIR}/${name}/backgrounds`
    if (!GLib.file_test(bgDir, GLib.FileTest.IS_DIR)) return false

    try {
        const dir = GLib.Dir.open(bgDir, 0)
        const files: string[] = []
        let fname: string | null
        while ((fname = dir.read_name()) !== null) {
            files.push(fname)
        }
        if (files.length === 0) return false

        files.sort()

        let currentFile = ""
        try {
            const saved = readFile(WALLPAPER_FILE).trim()
            const idx = saved.lastIndexOf("/")
            if (idx >= 0) currentFile = saved.substring(idx + 1)
        } catch { }

        let nextIndex = 0
        if (currentFile) {
            const currentIndex = files.indexOf(currentFile)
            if (currentIndex >= 0) {
                nextIndex = (currentIndex + 1) % files.length
            }
        }

        const wallpaperPath = `${bgDir}/${files[nextIndex]}`

        hyprpaperIpc(`preload ${wallpaperPath}`)
        const result = hyprpaperIpc(`wallpaper ,${wallpaperPath}`)

        ensureDir(PERSIST_DIR)
        writeFile(WALLPAPER_FILE, wallpaperPath)

        console.log(`[theme] Wallpaper: ${files[nextIndex]}`)
        return result === "ok"
    } catch (e) {
        console.warn(`[theme] Failed to cycle wallpaper: ${e}`)
        return false
    }
}

function loadTheme(name: string): boolean {
    const palette = readPalette(name)
    if (!palette) return false

    const css = generateGtkCss(palette)
    App.reset_css()
    App.apply_css(css)

    writeHyprlandTheme(palette)
    writeGhosttyTheme(palette)
    writeBtopTheme(palette)
    writeStarshipConfig(palette)

    switchWallpaper(name)

    ensureDir(PERSIST_DIR)
    writeFile(PERSIST_FILE, name)
    setCurrentTheme(name)

    console.log(`[theme] Applied theme: ${name}`)
    return true
}

function getCurrentTheme(): string {
    return currentTheme()
}

function initTheme(): void {
    let name = "catppuccin"
    try {
        const persisted = readFile(PERSIST_FILE).trim()
        if (persisted && getThemeList().includes(persisted)) {
            name = persisted
        }
    } catch { }

    loadTheme(name)
}

export { loadTheme, getCurrentTheme, getThemeList, initTheme, currentTheme, nextWallpaper }
