import GLib from "gi://GLib"
import App from "ags/gtk4/app"
import style from "./style.scss"
import lightStyle from "./light.scss"

const HOME = GLib.get_home_dir()
export const CURRENT = `${HOME}/.config/lkasper-hyprland/current`
export const COLORS = `${CURRENT}/colors.json`
export const STATE = `${HOME}/.config/lkasper-hyprland/state`

const KEYS = [
    "base00", "base01", "base02", "base03", "base04", "base05", "base06", "base07",
    "base08", "base09", "base0A", "base0B", "base0C", "base0D", "base0E", "base0F",
    "accent", "hairline", "shade",
]

const FALLBACK_PALETTE: Record<string, string> = {
    base00: "12131a", base01: "1b1d27", base02: "2a2d3a", base03: "3a3f52",
    base04: "c8ccd8", base05: "e6e9f0", base06: "eef1f6", base07: "ffffff",
    base08: "e06c75", base09: "d19a66", base0A: "e5c07b", base0B: "98c379",
    base0C: "56b6c2", base0D: "61afef", base0E: "c678dd", base0F: "be5046",
    accent: "61afef", hairline: "ffffff", shade: "000000",
    mode: "dark",
}

export function read(path: string): string | null {
    try {
        const [ok, bytes] = GLib.file_get_contents(path)
        if (ok) return new TextDecoder().decode(bytes)
    } catch {
    }
    return null
}

function palette(): Record<string, string> {
    const raw = read(COLORS)
    if (raw) {
        try {
            const parsed = JSON.parse(raw) as Record<string, string>
            if (typeof parsed.base00 === "string") return parsed
        } catch {
        }
    }
    return FALLBACK_PALETTE
}

export function activeMode(): string {
    return palette().mode === "light" ? "light" : "dark"
}

function paletteCss(p: Record<string, string>): string {
    const defs = KEYS.filter((k) => typeof p[k] === "string").map(
        (k) => `@define-color ${k} #${String(p[k]).replace(/^#/, "")};`,
    )
    if (typeof p.accent !== "string") {
        defs.push(`@define-color accent #${String(p.base0D).replace(/^#/, "")};`)
    }
    if (typeof p.hairline !== "string") {
        defs.push(`@define-color hairline #${p.mode === "light" ? "000000" : "ffffff"};`)
    }
    if (typeof p.shade !== "string") {
        defs.push("@define-color shade #000000;")
    }
    return defs.join("\n")
}

export function themedCss(): string {
    const p = palette()
    const sheets = p.mode === "light" ? [style, lightStyle] : [style]
    return [paletteCss(p), ...sheets].join("\n")
}

export function applyTheme(): void {
    App.reset_css()
    App.apply_css(themedCss(), false)
}

function signature(): string {
    return read(STATE)?.trim() ?? read(COLORS) ?? ""
}

export function watchTheme(): void {
    let last = signature()
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, () => {
        const cur = signature()
        if (cur !== last) {
            last = cur
            applyTheme()
        }
        return GLib.SOURCE_CONTINUE
    })
}
