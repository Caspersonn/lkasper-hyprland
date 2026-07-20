import Gdk from "gi://Gdk"
import GLib from "gi://GLib"
import AstalApps from "gi://AstalApps"
import AstalHyprland from "gi://AstalHyprland"
import App from "ags/gtk4/app"
import { For, createBinding, createComputed, createState } from "ags"
import { Astal, Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"

interface LauncherItem {
    key: string
    name: string
    icon: string
    app: AstalApps.Application
}

const [visible, setVisible] = createState(false)
const [connector, setConnector] = createState<string | null>(null)
const [query, setQuery] = createState("")
// Selection is tracked by the item's stable key (app entry id), never by a
// positional index: <For> reuses row widgets across query changes, so a
// captured index goes stale and highlights the wrong row.
const [selectedKey, setSelectedKey] = createState("")

const hypr = AstalHyprland.get_default()
const appDb = new AstalApps.Apps({
    nameMultiplier: 2,
    entryMultiplier: 0,
    executableMultiplier: 2,
})
const entries = new Map<string, Gtk.Entry>()

function toItem(app: AstalApps.Application): LauncherItem {
    return {
        key: app.get_entry(),
        name: app.get_name(),
        icon: app.get_icon_name() || "application-x-executable",
        app,
    }
}

function queryApps(text: string): LauncherItem[] {
    const q = text.trim()
    const apps = q ? appDb.fuzzy_query(q) : appDb.get_list()
    return apps.map(toItem)
}

const results = createComputed([query], queryApps)
const emptyVisible = createComputed([results], (items) => items.length === 0)

// Select the first result (top match), used on open and on every query change.
function selectFirst() {
    setSelectedKey(results()[0]?.key ?? "")
}

// Move selection by `delta` within the current (fresh) result ordering.
function move(delta: number) {
    const items = results()
    if (items.length === 0) return
    const cur = items.findIndex((it) => it.key === selectedKey())
    const base = cur < 0 ? 0 : cur
    const next = Math.max(0, Math.min(base + delta, items.length - 1))
    setSelectedKey(items[next].key)
}

function close() {
    setVisible(false)
}

// Launch an app detached from the AGS shell. A plain Gio launch (app.launch())
// spawns the app inside the shell service's systemd cgroup, so it gets killed
// when the bar restarts/crashes. Instead dispatch through Hyprland (over its IPC
// socket, independent of the shell service's stripped PATH) and start it with
// `uwsm app`, which places the app in its own systemd scope.
function launchApp(app: AstalApps.Application): void {
    const entry = app.get_entry()
    if (entry) {
        hypr.dispatch("exec", `uwsm app -- ${entry}`)
        // Preserve the frequency ranking that app.launch() would have bumped.
        app.frequency += 1
    } else {
        app.launch()
    }
}

function launchSelected() {
    const items = results()
    const item = items.find((it) => it.key === selectedKey()) ?? items[0]
    if (!item) return
    launchApp(item.app)
    close()
}

function focusEntry(name: string | null) {
    if (!name) return
    GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
        const entry = entries.get(name)
        if (entry) {
            entry.text = ""
            entry.grab_focus()
        }
        return GLib.SOURCE_REMOVE
    })
}

// True if `widget` is `ancestor` or nested somewhere beneath it.
function isInside(widget: Gtk.Widget | null, ancestor: Gtk.Widget | null): boolean {
    let w = widget
    while (w) {
        if (w === ancestor) return true
        w = w.get_parent()
    }
    return false
}

export function toggleLauncher() {
    if (visible()) {
        close()
        return
    }
    const fm = hypr.focusedMonitor
    const name = fm ? fm.name : null
    setQuery("")
    selectFirst()
    setConnector(name)
    setVisible(true)
    focusEntry(name)
}

function LauncherWindow(gdkmonitor: Gdk.Monitor) {
    const myConnector = gdkmonitor.get_connector() ?? "unknown"
    const winVisible = createComputed(
        () => visible() && connector() === myConnector,
    )

    // Per-window widget refs (keyed by stable item key) for scroll-into-view.
    const rowWidgets = new Map<string, Gtk.Widget>()
    let scrolledWin: Gtk.ScrolledWindow | null = null
    let modalBox: Gtk.Widget | null = null
    let backdropBox: Gtk.Widget | null = null

    function scrollToSelected() {
        if (!(visible() && connector() === myConnector)) return
        if (!scrolledWin) return
        const row = rowWidgets.get(selectedKey())
        if (!row) return
        const adj = scrolledWin.get_vadjustment()
        const alloc = row.get_allocation()
        const top = alloc.y
        const bottom = alloc.y + alloc.height
        if (top < adj.value) {
            adj.value = top
        } else if (bottom > adj.value + adj.page_size) {
            adj.value = bottom - adj.page_size
        }
    }
    selectedKey.subscribe(scrollToSelected)

    // Keyboard handling lives on the window (CAPTURE phase) so Up/Down/Return/
    // Escape are intercepted before the focused entry acts on them; other keys
    // fall through to the entry for normal typing.
    const keys = new Gtk.EventControllerKey()
    keys.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)
    keys.connect("key-pressed", (_c, keyval) => {
        if (keyval === Gdk.KEY_Escape) {
            close()
            return true
        }
        if (keyval === Gdk.KEY_Down) {
            move(1)
            return true
        }
        if (keyval === Gdk.KEY_Up) {
            move(-1)
            return true
        }
        if (keyval === Gdk.KEY_Return || keyval === Gdk.KEY_KP_Enter) {
            launchSelected()
            return true
        }
        return false
    })

    // Close only when the press lands outside the modal card. We pick the
    // widget under the pointer instead of claiming the sequence, so row
    // buttons keep receiving their own clicks.
    const backdropClick = new Gtk.GestureClick()
    backdropClick.connect("pressed", (_g, _n, x, y) => {
        const picked = backdropBox?.pick(x, y, Gtk.PickFlags.DEFAULT) ?? null
        if (!isInside(picked, modalBox)) close()
    })

    return <window
        name={`launcher-${myConnector}`}
        namespace="launcher"
        application={App}
        gdkmonitor={gdkmonitor}
        class="launcher"
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
            class="launcher-backdrop"
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
                class="launcher-modal"
                orientation={Gtk.Orientation.VERTICAL}
                halign={Gtk.Align.CENTER}
                valign={Gtk.Align.CENTER}
                hexpand
                vexpand
                widthRequest={560}
                $={(self) => (modalBox = self)}
            >
                <entry
                    class="launcher-search"
                    placeholderText="Search apps"
                    $={(self: Gtk.Entry) => {
                        entries.set(myConnector, self)
                        self.connect("notify::text", () => {
                            setQuery(self.text)
                            selectFirst()
                        })
                    }}
                />
                <label
                    class="launcher-empty"
                    xalign={0.5}
                    halign={Gtk.Align.CENTER}
                    label="No applications found"
                    visible={emptyVisible}
                />
                <scrolledwindow
                    class="launcher-results"
                    hscrollbarPolicy={Gtk.PolicyType.NEVER}
                    vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
                    maxContentHeight={360}
                    propagateNaturalHeight
                    $={(self: Gtk.ScrolledWindow) => (scrolledWin = self)}
                >
                    <box class="launcher-list" orientation={Gtk.Orientation.VERTICAL}>
                        <For each={results} id={(item: LauncherItem) => item.key}>
                            {(item: LauncherItem) => {
                                const rowClasses = createComputed([selectedKey], (k) =>
                                    k === item.key
                                        ? ["launcher-row", "selected"]
                                        : ["launcher-row"],
                                )
                                const motion = new Gtk.EventControllerMotion()
                                motion.connect("enter", () => setSelectedKey(item.key))
                                return (
                                    <button
                                        cssClasses={rowClasses}
                                        onClicked={() => {
                                            launchApp(item.app)
                                            close()
                                        }}
                                        $={(self) => {
                                            rowWidgets.set(item.key, self)
                                            self.add_controller(motion)
                                        }}
                                    >
                                        <box valign={Gtk.Align.CENTER}>
                                            <image class="launcher-app-icon" iconName={item.icon} />
                                            <label
                                                class="launcher-app-name"
                                                xalign={0}
                                                hexpand
                                                label={item.name}
                                            />
                                        </box>
                                    </button>
                                )
                            }}
                        </For>
                    </box>
                </scrolledwindow>
            </box>
        </box>
    </window>
}

export function Launcher() {
    return (
        <button class="launcher island-btn" onClicked={() => execAsync(["ags", "request", "toggle-launcher"])}>
            <label class="launcher-icon" halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} label={"\uf313"} />
        </button>
    )
}

export function initLauncher() {
    const monitors = createBinding(App, "monitors")
    return (
        <For each={monitors} cleanup={(win) => (win as Gtk.Window).destroy()}>
            {(monitor: Gdk.Monitor) => LauncherWindow(monitor)}
        </For>
    )
}

