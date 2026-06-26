import { execAsync } from "ags/process"
import { Gtk } from "ags/gtk4"
import { glyph } from "./glyphs"

type Action = { icon: string; cls: string; label: string; cmd: string[] }

const ACTIONS: Action[] = [
    { icon: glyph.lock, cls: "pm-lock", label: "Lock", cmd: ["hyprlock"] },
    { icon: glyph.powerSleep, cls: "pm-suspend", label: "Suspend", cmd: ["systemctl", "suspend"] },
    { icon: glyph.logout, cls: "pm-logout", label: "Log out", cmd: ["hyprctl", "dispatch", "exit"] },
    { icon: glyph.restart, cls: "pm-reboot", label: "Reboot", cmd: ["systemctl", "reboot"] },
    { icon: glyph.power, cls: "pm-shutdown", label: "Shut down", cmd: ["systemctl", "poweroff"] },
]

function PowerMenu(): Gtk.Popover {
    const pop = new Gtk.Popover()
    pop.set_has_arrow(false)
    pop.add_css_class("popover-wrap")

    const content = (
        <box class="power-menu" orientation={Gtk.Orientation.VERTICAL}>
            {ACTIONS.map((a) => (
                <button
                    class={`pm-row ${a.cls}`}
                    onClicked={() => {
                        pop.popdown()
                        execAsync(a.cmd)
                    }}
                >
                    <box>
                        <label class="pm-icon" label={a.icon} />
                        <label class="pm-label" label={a.label} />
                    </box>
                </button>
            ))}
        </box>
    ) as Gtk.Widget

    pop.set_child(content)
    return pop
}

export default function PowerButton() {
    const pop = PowerMenu()
    return (
        <button
            class="power asg-pow island-sub"
            onClicked={() => pop.popup()}
            $={(self) => pop.set_parent(self)}
        >
            <label class="power-icon" label={glyph.power} />
        </button>
    )
}
