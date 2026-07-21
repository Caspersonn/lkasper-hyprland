import GLib from "gi://GLib"
import App from "ags/gtk4/app"
import style from "./style.scss"

const HOME = GLib.get_home_dir()
export const CURRENT = `${HOME}/.config/lkasper-hyprland/current/theme.name`
const THEMES = `${HOME}/.local/share/lkasper-hyprland/themes`
const FALLBACK = "wood-dark"

const KEYS = [
    "base00", "base01", "base02", "base03", "base04", "base05", "base06", "base07",
    "base08", "base09", "base0A", "base0B", "base0C", "base0D", "base0E", "base0F",
]

const FALLBACK_PALETTE: Record<string, string> = {
    base00: "12131a", base01: "1b1d27", base02: "2a2d3a", base03: "3a3f52",
    base04: "c8ccd8", base05: "e6e9f0", base06: "eef1f6", base07: "ffffff",
    base08: "e06c75", base09: "d19a66", base0A: "e5c07b", base0B: "98c379",
    base0C: "56b6c2", base0D: "61afef", base0E: "c678dd", base0F: "be5046",
    accent: "61afef",
}

export function read(path: string): string | null {
    try {
        const [ok, bytes] = GLib.file_get_contents(path)
        if (ok) return new TextDecoder().decode(bytes)
    } catch {
    }
    return null
}

function activeName(): string {
    return (read(CURRENT) ?? FALLBACK).trim() || FALLBACK
}

function paletteFor(name: string): Record<string, string> {
    const raw = read(`${THEMES}/${name}/colors.json`) ?? read(`${THEMES}/${FALLBACK}/colors.json`)
    if (raw) {
        try {
            return JSON.parse(raw) as Record<string, string>
        } catch {
        }
    }
    return FALLBACK_PALETTE
}

function paletteCss(): string {
    const p = paletteFor(activeName())
    const defs = KEYS.filter((k) => typeof p[k] === "string").map(
        (k) => `@define-color ${k} #${String(p[k]).replace(/^#/, "")};`,
    )
    const accent = p.accent ?? p.base0D
    if (typeof accent === "string") {
        defs.push(`@define-color accent #${accent.replace(/^#/, "")};`)
    }
    return defs.join("\n")
}

export function themedCss(): string {
    return `${paletteCss()}\n${style}`
}

export function applyTheme(): void {
    App.reset_css()
    App.apply_css(themedCss(), false)
}

export function watchTheme(): void {
    let last = activeName()
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1500, () => {
        const cur = activeName()
        if (cur !== last) {
            last = cur
            applyTheme()
        }
        return GLib.SOURCE_CONTINUE
    })
}
