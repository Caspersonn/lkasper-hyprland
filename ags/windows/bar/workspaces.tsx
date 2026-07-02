import AstalHyprland from "gi://AstalHyprland"
import { createBinding, createComputed, For } from "ags"
import { Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"

const hypr = AstalHyprland.get_default()

function monIndex(name: string): number {
    let h = 0
    for (let i = 0; i < name.length; i++) {
        h = (h * 31 + name.charCodeAt(i)) >>> 0
    }
    return h % 5
}

function WorkspaceButton(ws: AstalHyprland.Workspace) {
    const focused = createBinding(hypr, "focusedWorkspace")
    const clients = createBinding(ws, "clients")

    const cssClasses = createComputed([focused, clients], (fw, cs) => {
        const isFocused = fw?.id === ws.id
        const hasApps = cs.length > 0
        const state = isFocused ? "focused" : hasApps ? "occupied" : "empty"
        const mon = ws.monitor?.name ?? ""
        return ["asg-ws", state, `mon-${monIndex(mon)}`]
    })

    const underlineVisible = createComputed(
        [focused, clients],
        (fw, cs) => fw?.id === ws.id || cs.length > 0,
    )

    const underlineWidth = createComputed([clients], (cs) => {
        const n = Math.max(1, Math.min(cs.length, 3))
        return n * 20
    })

    const appIcons = createComputed([clients], (cs) => {
        const out: { key: string; cls: string }[] = []
        for (const c of cs) {
            const cls = (c.class ?? "").toLowerCase()
            if (cls) out.push({ key: c.address, cls })
        }
        return out.slice(0, 3)
    })

    return (
        <button
            cssClasses={cssClasses}
            valign={Gtk.Align.CENTER}
            onClicked={() =>
                execAsync(["hyprctl", "dispatch", "workspace", `${ws.id}`])
            }
        >
            <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER}>
                <box class="ws-row" halign={Gtk.Align.CENTER}>
                    <box class="ws-icons">
                        <For each={appIcons} id={(item) => item.key}>
                            {(item: { key: string; cls: string }) => (
                                <image class="ws-icon" iconName={item.cls} />
                            )}
                        </For>
                    </box>
                    <label class="ws-num" label={`${ws.id}`} />
                </box>
                <box
                    class="ws-underline"
                    halign={Gtk.Align.CENTER}
                    widthRequest={underlineWidth}
                    visible={underlineVisible}
                />
            </box>
        </button>
    )
}

export default function Workspaces() {
    const workspaces = createComputed(
        [createBinding(hypr, "workspaces")],
        (ws) => ws.filter((w) => w.id > 0).sort((a, b) => a.id - b.id),
    )
    return (
        <box class="workspaces">
            <For each={workspaces}>
                {(ws: AstalHyprland.Workspace) => WorkspaceButton(ws)}
            </For>
        </box>
    )
}
