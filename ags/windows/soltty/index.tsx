import Gdk from "gi://Gdk"
import GLib from "gi://GLib"
import AstalHyprland from "gi://AstalHyprland"
import App from "ags/gtk4/app"
import { For, createBinding, createComputed, createState } from "ags"
import { Astal, Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { glyph } from "../bar/glyphs"
import { isInside } from "../utils"
import {
    solttyState,
    setSolttyActive,
    refreshCurrent,
    startTimer,
    stopTimer,
    updateRunningDescription,
    updateRunningProject,
    type Project,
    type RecentEntry,
} from "./service"

const hypr = AstalHyprland.get_default()

const [visible, setVisible] = createState(false)
const [connector, setConnector] = createState<string | null>(null)
const [desc, setDesc] = createState("")
const [selectedProject, setSelectedProject] = createState<string | null>(null)
const [projectMenuOpen, setProjectMenuOpen] = createState(false)
const [projectQuery, setProjectQuery] = createState("")

const descEntries = new Map<string, Gtk.Entry>()
const searchEntries = new Map<string, Gtk.Entry>()

const filteredProjects = createComputed(
    [solttyState.projects, projectQuery],
    (list, q) => {
        const query = q.trim().toLowerCase()
        if (!query) return list
        return list.filter(
            (p) =>
                p.name.toLowerCase().includes(query) ||
                (p.client ?? "").toLowerCase().includes(query),
        )
    },
)

const elapsedText = createComputed(
    [solttyState.running, solttyState.startedAt, solttyState.tick],
    (running, started) => {
        if (!running || !started) return "00:00:00"
        const e = Math.max(0, Math.floor((Date.now() - started) / 1000))
        const h = Math.floor(e / 3600)
        const m = Math.floor((e % 3600) / 60)
        const s = e % 60
        return [h, m, s].map((n) => String(n).padStart(2, "0")).join(":")
    },
)

function paintDot(w: Gtk.Widget, color: string): Gtk.CssProvider {
    const p = new Gtk.CssProvider()
    try {
        p.load_from_string(`* { background-color: ${color}; }`)
    } catch {
    }
    w.get_style_context().add_provider(p, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
    return p
}

function repaintDot(p: Gtk.CssProvider, color: string): void {
    try {
        p.load_from_string(`* { background-color: ${color}; }`)
    } catch {
    }
}

function focusWidget(map: Map<string, Gtk.Entry>, name: string | null): void {
    if (!name) return
    GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
        map.get(name)?.grab_focus()
        return GLib.SOURCE_REMOVE
    })
}

function applyDesc(name: string | null, text: string): void {
    setDesc(text)
    const e = name ? descEntries.get(name) : null
    if (e && e.text !== text) e.text = text
}

function close(): void {
    setVisible(false)
    setProjectMenuOpen(false)
    setSolttyActive(false)
}

function primaryAction(): void {
    if (solttyState.running()) {
        stopTimer()
    } else {
        startTimer(desc(), selectedProject())
    }
}

function openProjectMenu(name: string | null): void {
    setProjectQuery("")
    setProjectMenuOpen(true)
    if (name) {
        const e = searchEntries.get(name)
        if (e) e.text = ""
    }
    focusWidget(searchEntries, name)
}

function closeProjectMenu(name: string | null): void {
    setProjectMenuOpen(false)
    setProjectQuery("")
    focusWidget(descEntries, name)
}

function toggleProjectMenu(name: string | null): void {
    if (projectMenuOpen()) closeProjectMenu(name)
    else openProjectMenu(name)
}

function pickProject(name: string | null, projName: string): void {
    setSelectedProject(projName)
    closeProjectMenu(name)
    updateRunningProject(projName)
}

function selectFirstProject(name: string | null): void {
    const p = filteredProjects()[0]
    if (p) pickProject(name, p.name)
    else closeProjectMenu(name)
}

export function toggleSoltty(): void {
    if (visible()) {
        close()
        return
    }
    const fm = hypr.focusedMonitor
    const name = fm ? fm.name : null
    setConnector(name)
    setProjectMenuOpen(false)
    setProjectQuery("")
    const initDesc = solttyState.running() ? solttyState.runningDesc() : ""
    applyDesc(name, initDesc)
    if (solttyState.running()) setSelectedProject(solttyState.runningProject())
    setVisible(true)
    setSolttyActive(true)
    focusWidget(descEntries, name)
    refreshCurrent().then(() => {
        if (!visible()) return
        if (solttyState.running() && desc().trim() === "") {
            applyDesc(name, solttyState.runningDesc())
            setSelectedProject(solttyState.runningProject())
        }
    })
}

function SolttyWindow(gdkmonitor: Gdk.Monitor) {
    const myConnector = gdkmonitor.get_connector() ?? "unknown"
    const winVisible = createComputed(
        () => visible() && connector() === myConnector,
    )

    let modalBox: Gtk.Widget | null = null
    let backdropBox: Gtk.Widget | null = null

    const triggerLabel = createComputed([selectedProject], (p) => p ?? "No project")
    const triggerColor = createComputed(
        [selectedProject, solttyState.projects],
        (p, list) => list.find((x) => x.name === p)?.color ?? "#6a615a",
    )

    const statusClasses = createComputed([solttyState.running], (r) =>
        r ? ["soltty-status", "running"] : ["soltty-status", "idle"],
    )
    const statusDotClasses = createComputed([solttyState.running], (r) =>
        r ? ["soltty-status-dot", "running"] : ["soltty-status-dot"],
    )
    const elapsedClasses = createComputed([solttyState.running], (r) =>
        r ? ["soltty-elapsed", "running"] : ["soltty-elapsed"],
    )
    const statusLabel = createComputed([solttyState.running], (r) => (r ? "Recording" : "Idle"))
    const statusSub = createComputed(
        [solttyState.running, solttyState.runningProject, solttyState.runningDesc],
        (r, proj, d) => {
            if (!r) return "no active timer"
            const parts = [proj, d].filter((x) => x && x.length) as string[]
            return parts.length ? parts.join(" · ") : "tracking to solidtime"
        },
    )

    const connClasses = createComputed([solttyState.connected], (c) =>
        c ? ["soltty-conn-dot", "ok"] : ["soltty-conn-dot", "bad"],
    )
    const connText = createComputed([solttyState.connected], (c) =>
        c ? "solidtime · connected" : "disconnected",
    )

    const primaryClasses = createComputed([solttyState.running], (r) =>
        r ? ["soltty-primary", "stop"] : ["soltty-primary", "start"],
    )
    const primaryLabel = createComputed([solttyState.running], (r) => (r ? "Stop timer" : "Start timer"))
    const primaryGlyph = createComputed([solttyState.running], (r) => (r ? glyph.stop : glyph.play))
    const actionKey = createComputed([solttyState.running], (r) => (r ? "S" : "Enter"))

    const keys = new Gtk.EventControllerKey()
    keys.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)
    keys.connect("key-pressed", (_c, keyval) => {
        if (keyval === Gdk.KEY_Escape) {
            if (projectMenuOpen()) {
                closeProjectMenu(myConnector)
                return true
            }
            close()
            return true
        }
        if (keyval === Gdk.KEY_Return || keyval === Gdk.KEY_KP_Enter) {
            if (projectMenuOpen()) {
                selectFirstProject(myConnector)
                return true
            }
            primaryAction()
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
        name={`soltty-${myConnector}`}
        namespace="soltty"
        application={App}
        gdkmonitor={gdkmonitor}
        class="soltty"
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
            class="soltty-backdrop"
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
                class="soltty-card"
                orientation={Gtk.Orientation.VERTICAL}
                halign={Gtk.Align.CENTER}
                valign={Gtk.Align.CENTER}
                widthRequest={540}
                $={(self) => (modalBox = self)}
            >
                <box class="soltty-header" valign={Gtk.Align.CENTER}>
                    <label class="soltty-logo" label="s" valign={Gtk.Align.CENTER} />
                    <label class="soltty-word" label="soltty" valign={Gtk.Align.CENTER} />
                    <box hexpand />
                    <box class="soltty-conn" valign={Gtk.Align.CENTER}>
                        <box cssClasses={connClasses} valign={Gtk.Align.CENTER} />
                        <label class="soltty-conn-text" label={connText} />
                    </box>
                </box>

                <box class="soltty-sec" valign={Gtk.Align.CENTER}>
                    <label class="soltty-sec-label" label="TIMER" />
                    <box class="soltty-sec-rule" hexpand valign={Gtk.Align.CENTER} />
                </box>
                <box cssClasses={statusClasses} valign={Gtk.Align.CENTER}>
                    <box valign={Gtk.Align.CENTER}>
                        <box cssClasses={statusDotClasses} valign={Gtk.Align.CENTER} />
                        <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER}>
                            <label class="soltty-status-label" xalign={0} label={statusLabel} />
                            <label class="soltty-status-sub" xalign={0} label={statusSub} />
                        </box>
                    </box>
                    <box hexpand />
                    <label cssClasses={elapsedClasses} label={elapsedText} valign={Gtk.Align.CENTER} />
                </box>

                <label class="soltty-flabel" xalign={0} label="DESCRIPTION" />
                <entry
                    class="soltty-input"
                    placeholderText="What are you working on?"
                    $={(self: Gtk.Entry) => {
                        descEntries.set(myConnector, self)
                        let debounce = 0
                        self.connect("notify::text", () => {
                            setDesc(self.text)
                            if (debounce) GLib.source_remove(debounce)
                            debounce = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 600, () => {
                                debounce = 0
                                updateRunningDescription(self.text)
                                return GLib.SOURCE_REMOVE
                            })
                        })
                    }}
                />

                <box class="soltty-proj-field" orientation={Gtk.Orientation.VERTICAL}>
                    <label class="soltty-flabel" xalign={0} label="PROJECT" />
                    <button
                        class="soltty-proj-trigger"
                        onClicked={() => toggleProjectMenu(myConnector)}
                    >
                        <box valign={Gtk.Align.CENTER}>
                            <box
                                class="soltty-dot"
                                valign={Gtk.Align.CENTER}
                                $={(self) => {
                                    const p = paintDot(self, triggerColor())
                                    triggerColor.subscribe(() => repaintDot(p, triggerColor()))
                                }}
                            />
                            <label class="soltty-proj-name" xalign={0} hexpand label={triggerLabel} />
                            <label class="soltty-proj-caret" label={glyph.chevronRight} />
                        </box>
                    </button>
                    <box
                        class="soltty-proj-panel"
                        orientation={Gtk.Orientation.VERTICAL}
                        visible={projectMenuOpen}
                    >
                        <entry
                            class="soltty-proj-search"
                            placeholderText="Search projects"
                            $={(self: Gtk.Entry) => {
                                searchEntries.set(myConnector, self)
                                self.connect("notify::text", () => setProjectQuery(self.text))
                            }}
                        />
                        <scrolledwindow
                            hscrollbarPolicy={Gtk.PolicyType.NEVER}
                            vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
                            maxContentHeight={220}
                            propagateNaturalHeight
                        >
                            <box class="soltty-menu" orientation={Gtk.Orientation.VERTICAL}>
                                <For each={filteredProjects} id={(p: Project) => p.name}>
                                    {(p: Project) => (
                                        <button
                                            class="soltty-menu-item"
                                            onClicked={() => pickProject(myConnector, p.name)}
                                        >
                                            <box valign={Gtk.Align.CENTER}>
                                                <box class="soltty-dot" valign={Gtk.Align.CENTER} $={(w) => paintDot(w, p.color)} />
                                                <label class="soltty-menu-name" xalign={0} hexpand label={p.name} />
                                                <label class="soltty-menu-client" label={p.client ?? ""} />
                                            </box>
                                        </button>
                                    )}
                                </For>
                            </box>
                        </scrolledwindow>
                    </box>
                </box>

                <box class="soltty-actions" valign={Gtk.Align.CENTER}>
                    <button
                        cssClasses={primaryClasses}
                        hexpand
                        onClicked={() => primaryAction()}
                    >
                        <box halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
                            <label class="soltty-primary-glyph" label={primaryGlyph} />
                            <label class="soltty-primary-label" label={primaryLabel} />
                        </box>
                    </button>
                    <box class="soltty-keys" valign={Gtk.Align.CENTER}>
                        <label class="soltty-key" label="Super" />
                        <label class="soltty-key" label={actionKey} />
                    </box>
                </box>

                <box class="soltty-sec" valign={Gtk.Align.CENTER}>
                    <label class="soltty-sec-label" label="RECENT" />
                    <box class="soltty-sec-rule" hexpand valign={Gtk.Align.CENTER} />
                    <label class="soltty-sec-caption" label="soltty list" />
                </box>
                <box class="soltty-recent" orientation={Gtk.Orientation.VERTICAL}>
                    <For each={solttyState.recent} id={(e: RecentEntry) => e.id}>
                        {(e: RecentEntry) => (
                            <box class="soltty-recent-row" valign={Gtk.Align.CENTER}>
                                <label class="soltty-recent-start" label={e.start} />
                                <label class="soltty-recent-dur" label={e.dur} />
                                <box class="soltty-dot" valign={Gtk.Align.CENTER} $={(w) => paintDot(w, e.color)} />
                                <label class="soltty-recent-desc" xalign={0} hexpand label={e.desc} />
                                <label class="soltty-recent-id" label={e.id} />
                            </box>
                        )}
                    </For>
                </box>
            </box>
        </box>
    </window>
}

export function SolttyIndicator() {
    const cls = createComputed([solttyState.running], (r) =>
        r ? ["soltty-bar-btn", "island-btn", "running"] : ["soltty-bar-btn", "island-btn"],
    )
    const icon = createComputed([solttyState.running], (r) => (r ? "󱫡" : "󱫟"))
    return (
        <button cssClasses={cls} onClicked={() => execAsync(["ags", "request", "toggle-soltty"])}>
            <box valign={Gtk.Align.CENTER}>
                <label class="soltty-bar-icon" valign={Gtk.Align.CENTER} label={icon} />
                <label class="soltty-bar-time" valign={Gtk.Align.CENTER} label={elapsedText} />
            </box>
        </button>
    )
}

export function initSoltty() {
    const monitors = createBinding(App, "monitors")
    return (
        <For each={monitors} cleanup={(win) => (win as Gtk.Window).destroy()}>
            {(monitor: Gdk.Monitor) => SolttyWindow(monitor)}
        </For>
    )
}
