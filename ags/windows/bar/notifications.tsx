import AstalNotifd from "gi://AstalNotifd"
import { createBinding } from "ags"
import { Gtk } from "ags/gtk4"
import { NotificationPopover } from "../notifications/center"
import { glyph } from "./glyphs"

export default function NotificationBell({ connector }: { connector: string }) {
    const notifd = AstalNotifd.get_default()
    const dnd = createBinding(notifd, "dontDisturb")
    const count = createBinding(notifd, "notifications").as(n => n.length)
    const pop = NotificationPopover(connector)
    return <button
        class="notifications island-sub"
        onClicked={() => (pop.get_visible() ? pop.popdown() : pop.popup())}
        $={(self) => pop.set_parent(self)}
    >
        <overlay>
            <label class="notif-bell" label={dnd.as(d => (d ? glyph.bellOff : glyph.bell))} />
            <label
                class="notif-badge"
                $type="overlay"
                halign={Gtk.Align.END}
                valign={Gtk.Align.START}
                visible={count.as(c => c > 0)}
                label={count.as(c => `${c}`)}
            />
        </overlay>
    </button>
}
