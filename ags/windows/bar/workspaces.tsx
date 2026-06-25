import AstalHyprland from "gi://AstalHyprland"
import { createBinding, createComputed, For } from "ags"
import { Gtk } from "ags/gtk4"
import { exec } from "ags/process"

const hypr = AstalHyprland.get_default()

// Always show these workspaces. The 10th is labelled "0" to match the
// `SUPER, 0` keybind (and the design mockup).
const WS_IDS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

function deviceIcon(connector: string): string {
    return connector.startsWith("eDP")
        ? "computer-laptop-symbolic"
        : "video-display-symbolic"
}

function ScreenPicker(id: number, popover: Gtk.Popover) {
    const monitors = createBinding(hypr, "monitors")
    return <box class="screen-picker" orientation={Gtk.Orientation.VERTICAL}>
        <label class="screen-picker-header" xalign={0} label={`Workspace ${id} → screen`} />
        <For each={monitors}>
            {(m: AstalHyprland.Monitor) => (
                <button
                    class="screen-row"
                    onClicked={() => {
                        exec(`hyprctl dispatch moveworkspacetomonitor ${id} ${m.name}`)
                        popover.popdown()
                    }}
                >
                    <box>
                        <image class="screen-icon" iconName={deviceIcon(m.name)} />
                        <box
                            orientation={Gtk.Orientation.VERTICAL}
                            hexpand
                            halign={Gtk.Align.START}
                            valign={Gtk.Align.CENTER}
                        >
                            <label class="screen-model" xalign={0} label={m.model || m.description || m.name} />
                            <label
                                class="screen-specs"
                                xalign={0}
                                label={`${m.width}×${m.height} @ ${Math.round(m.refreshRate)}Hz · ${m.name}`}
                            />
                        </box>
                    </box>
                </button>
            )}
        </For>
    </box>
}

function WorkspaceButton(id: number) {
    const workspaces = createBinding(hypr, "workspaces")
    const focused = createBinding(hypr, "focusedWorkspace")
    const clients = createBinding(hypr, "clients")

    // The Hyprland workspace for this id, if it currently exists.
    const ws = createComputed(() => workspaces().find(w => w.id === id) ?? null)

    const cssClasses = createComputed(() => {
        const w = ws()
        const fw = focused()
        const state = w == null ? "empty" : fw?.id === id ? "active" : "occupied"
        return ["workspace", state]
    })

    // Centered underline coloured by the bound monitor's accent. Existing
    // workspaces use their actual monitor; empty ones use their persistent
    // workspace-rule monitor; failing that, the focused monitor.
    // Representative app icon = the workspace's last-focused client's class.
    const appIcon = createComputed(() => {
        clients()
        const c = ws()?.lastClient
        return c?.class ? c.class.toLowerCase() : ""
    })
    const hasIcon = createComputed(() => appIcon() !== "")

    // Centered underline coloured by the bound monitor's accent. Existing
    // workspaces use their actual monitor; empty ones use their persistent
    // workspace-rule monitor; failing that, the focused monitor.
    const underlineClasses = createComputed(() => {
        if (focused()?.id !== id) return ["ws-underline"]
        return ["ws-underline", "ws-accent"]
    })

    const popover = new Gtk.Popover()
    popover.set_has_arrow(false)
    popover.set_child(ScreenPicker(id, popover) as unknown as Gtk.Widget)

    function setup(button: Gtk.Widget) {
        popover.set_parent(button)
        const gesture = new Gtk.GestureClick()
        gesture.set_button(3) // right mouse button
        gesture.connect("pressed", () => popover.popup())
        button.add_controller(gesture)
    }

    return <button
        valign={Gtk.Align.CENTER}
        cssClasses={cssClasses}
        onClicked={() => exec(`hyprctl dispatch workspace ${id}`)}
        $={setup}
    >
        <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER}>
            <box class="ws-row" halign={Gtk.Align.CENTER}>
                <image class="ws-icon" visible={hasIcon} iconName={appIcon} />
                <label class="ws-num" label={id === 10 ? "0" : `${id}`} />
            </box>
            <box cssClasses={underlineClasses} halign={Gtk.Align.CENTER} />
        </box>
    </button>
}

export default function Workspaces() {
    return <box class="workspaces" valign={Gtk.Align.CENTER}>
        {WS_IDS.map(id => WorkspaceButton(id))}
    </box>
}
