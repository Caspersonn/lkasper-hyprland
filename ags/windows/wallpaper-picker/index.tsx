import Gdk from "gi://Gdk"
import GLib from "gi://GLib"
import App from "ags/gtk4/app"
import AstalHyprland from "gi://AstalHyprland"
import { For, createBinding, createComputed, createState } from "ags"
import { Astal, Gtk } from "ags/gtk4"
import { isInside } from "../utils"
import { CURRENT, read } from "../../theme"

const HOME = GLib.get_home_dir()
const WALLPAPER_DIR = `${HOME}/.local/share/lkasper-hyprland/wallpapers`
const COLS = 3

interface Wallpaper {
    slug: string
    path: string
}

const hypr = AstalHyprland.get_default()
const [pVisible, setPVisible] = createState(false)
const [pConnector, setPConnector] = createState<string | null>(null)
const [selectedSlug, setSelectedSlug] = createState("")
const [activeSlug, setActiveSlug] = createState("")

function listWallpapers(): Wallpaper[] {
    const out: Wallpaper[] = []
    try {
        const dir = GLib.Dir.open(WALLPAPER_DIR, 0)
        let name: string | null
        while ((name = dir.read_name()) !== null) {
            const m = name.match(/^(.+)\.(?:png|jpe?g)$/i)
            if (m) out.push({ slug: m[1], path: `${WALLPAPER_DIR}/${name}` })
        }
        dir.close()
    } catch {
    }
    return out.sort((a, b) => a.slug.localeCompare(b.slug))
}

const WALLPAPERS = listWallpapers()

function readActive(): string {
    return (read(CURRENT) ?? "").trim()
}

function prettyName(slug: string): string {
    return slug.replace(/[-_]/g, " ").replace(/\b\w/g, (c) => c.toUpperCase())
}

function chunk<T>(arr: T[], n: number): T[][] {
    const rows: T[][] = []
    for (let i = 0; i < arr.length; i += n) rows.push(arr.slice(i, i + n))
    return rows
}

function close() {
    setPVisible(false)
}

function move(delta: number) {
    if (!WALLPAPERS.length) return
    const cur = WALLPAPERS.findIndex((w) => w.slug === selectedSlug())
    const base = cur < 0 ? 0 : cur
    const next = Math.max(0, Math.min(base + delta, WALLPAPERS.length - 1))
    setSelectedSlug(WALLPAPERS[next].slug)
}

function selectSlug(slug: string) {
    if (slug) hypr.dispatch("exec", `theme-switch ${slug}`)
    close()
}

export function toggleWallpaperPicker() {
    if (pVisible()) {
        close()
        return
    }
    const active = readActive()
    setActiveSlug(active)
    setSelectedSlug(
        WALLPAPERS.some((w) => w.slug === active) ? active : WALLPAPERS[0]?.slug ?? "",
    )
    const fm = hypr.focusedMonitor
    setPConnector(fm ? fm.name : null)
    setPVisible(true)
}

function paintThumb(self: Gtk.Box, path: string) {
    self.set_overflow(Gtk.Overflow.HIDDEN)
    const pic = Gtk.Picture.new_for_filename(path)
    pic.set_content_fit(Gtk.ContentFit.COVER)
    pic.set_can_shrink(true)
    pic.set_hexpand(true)
    pic.set_vexpand(true)
    self.append(pic)
}

function Tile(w: Wallpaper) {
    const cls = createComputed([selectedSlug, activeSlug], (sel, act) => {
        const c = ["wp-tile"]
        if (sel === w.slug) c.push("selected")
        if (act === w.slug) c.push("active")
        return c
    })
    const isCurrent = createComputed([activeSlug], (a) => a === w.slug)
    const motion = new Gtk.EventControllerMotion()
    motion.connect("enter", () => setSelectedSlug(w.slug))
    return (
        <button
            cssClasses={cls}
            onClicked={() => selectSlug(w.slug)}
            $={(self) => self.add_controller(motion)}
        >
            <box orientation={Gtk.Orientation.VERTICAL}>
                <box class="wp-thumb" $={(self: Gtk.Box) => paintThumb(self, w.path)} />
                <box class="wp-caption" valign={Gtk.Align.CENTER}>
                    <label class="wp-name" xalign={0} hexpand label={prettyName(w.slug)} />
                    <label class="wp-current" label="current" visible={isCurrent} />
                </box>
            </box>
        </button>
    )
}

function PickerWindow(gdkmonitor: Gdk.Monitor) {
    const myConnector = gdkmonitor.get_connector() ?? "unknown"
    const winVisible = createComputed(
        () => pVisible() && pConnector() === myConnector,
    )

    let modalBox: Gtk.Widget | null = null
    let backdropBox: Gtk.Widget | null = null

    const keys = new Gtk.EventControllerKey()
    keys.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)
    keys.connect("key-pressed", (_c, keyval) => {
        switch (keyval) {
            case Gdk.KEY_Escape:
                close()
                return true
            case Gdk.KEY_Left:
                move(-1)
                return true
            case Gdk.KEY_Right:
                move(1)
                return true
            case Gdk.KEY_Up:
                move(-COLS)
                return true
            case Gdk.KEY_Down:
                move(COLS)
                return true
            case Gdk.KEY_Return:
            case Gdk.KEY_KP_Enter:
                selectSlug(selectedSlug())
                return true
        }
        return false
    })

    const backdropClick = new Gtk.GestureClick()
    backdropClick.connect("pressed", (_g, _n, x, y) => {
        const picked = backdropBox?.pick(x, y, Gtk.PickFlags.DEFAULT) ?? null
        if (!isInside(picked, modalBox)) close()
    })

    return <window
        name={`wallpaper-picker-${myConnector}`}
        namespace="wallpaper-picker"
        application={App}
        gdkmonitor={gdkmonitor}
        class="wallpaper-picker"
        layer={Astal.Layer.OVERLAY}
        anchor={
            Astal.WindowAnchor.TOP |
            Astal.WindowAnchor.BOTTOM |
            Astal.WindowAnchor.LEFT |
            Astal.WindowAnchor.RIGHT
        }
        exclusivity={Astal.Exclusivity.IGNORE}
        keymode={Astal.Keymode.EXCLUSIVE}
        visible={winVisible}
        $={(self) => self.add_controller(keys)}
    >
        <box
            class="wp-backdrop"
            hexpand
            vexpand
            halign={Gtk.Align.FILL}
            valign={Gtk.Align.FILL}
            $={(self) => {
                backdropBox = self
                self.add_controller(backdropClick)
            }}
        >
            <box
                class="wp-modal"
                orientation={Gtk.Orientation.VERTICAL}
                halign={Gtk.Align.CENTER}
                valign={Gtk.Align.CENTER}
                $={(self) => (modalBox = self)}
            >
                <label class="wp-title" xalign={0} label="Wallpaper" />
                {WALLPAPERS.length === 0 ? (
                    <label class="wp-empty" label="No wallpapers found" />
                ) : (
                    <box class="wp-grid" orientation={Gtk.Orientation.VERTICAL}>
                        {chunk(WALLPAPERS, COLS).map((row) => (
                            <box class="wp-row">{row.map((w) => Tile(w))}</box>
                        ))}
                    </box>
                )}
            </box>
        </box>
    </window>
}

export function initWallpaperPicker() {
    const monitors = createBinding(App, "monitors")
    return (
        <For each={monitors} cleanup={(win) => (win as Gtk.Window).destroy()}>
            {(monitor: Gdk.Monitor) => PickerWindow(monitor)}
        </For>
    )
}
