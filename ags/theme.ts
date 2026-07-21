import GLib from "gi://GLib"
import App from "ags/gtk4/app"
import style from "./style.scss"

// Wallpaper-driven colours. The compiled stylesheet references GTK named colours
// (@base00..@base0F); this module supplies them from the active wallpaper's
// palette and re-applies the whole stylesheet when the wallpaper changes, so the
// shell recolours live without a rebuild or restart.

const HOME = GLib.get_home_dir()
const CURRENT = `${HOME}/.config/lkasper-hyprland/current/theme.name`
const THEMES = `${HOME}/.local/share/lkasper-hyprland/themes`
const FALLBACK = "wood-dark"

const KEYS = [
    "base00", "base01", "base02", "base03", "base04", "base05", "base06", "base07",
    "base08", "base09", "base0A", "base0B", "base0C", "base0D", "base0E", "base0F",
]

// Built-in dark fallback so the shell is never unstyled if the active wallpaper
// has no readable palette (missing/corrupt colors.json). Kept dark on purpose:
// the UI is force-dark (see design), so a dark fallback is always safe.
const FALLBACK_PALETTE: Record<string, string> = {
    base00: "12131a", base01: "1b1d27", base02: "2a2d3a", base03: "3a3f52",
    base04: "c8ccd8", base05: "e6e9f0", base06: "eef1f6", base07: "ffffff",
    base08: "e06c75", base09: "d19a66", base0A: "e5c07b", base0B: "98c379",
    base0C: "56b6c2", base0D: "61afef", base0E: "c678dd", base0F: "be5046",
    accent: "61afef",
}

function read(path: string): string | null {
    try {
        const [ok, bytes] = GLib.file_get_contents(path)
        if (ok) return new TextDecoder().decode(bytes)
    } catch {
        // missing/unreadable
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
            // corrupt JSON -> built-in fallback
        }
    }
    return FALLBACK_PALETTE
}

// A GTK @define-color block for the active wallpaper palette: base00..base0F
// (faithful ANSI) plus @accent, the wallpaper-derived accent the UI themes on.
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

// The full themed stylesheet: palette @define-colors + the structural rules, as
// one provider (so @baseNN references resolve to the active palette).
export function themedCss(): string {
    return `${paletteCss()}\n${style}`
}

// Replace the whole stylesheet with the active palette. A supplementary
// @define-color-only provider does NOT reliably override the initial one on a
// running shell, so we reset and re-apply the full sheet.
export function applyTheme(): void {
    App.reset_css()
    App.apply_css(themedCss(), false)
}

// Poll the active-theme pointer and recolour when it changes. Polling is more
// robust than a Gio file monitor across the ways the pointer gets rewritten.
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
