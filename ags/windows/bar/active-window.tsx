import AstalHyprland from "gi://AstalHyprland"
import Gdk from "gi://Gdk"
import Pango from "gi://Pango"
import { createState } from "ags"
import { Gtk } from "ags/gtk4"

const hypr = AstalHyprland.get_default()
const fallbackIcon = "application-x-executable-symbolic"

function resolveIcon(icon: string) {
    const display = Gdk.Display.get_default()
    const theme = display ? Gtk.IconTheme.get_for_display(display) : null
    return icon && theme?.has_icon(icon) ? icon : fallbackIcon
}

export default function ActiveWindow() {
    const [title, setTitle] = createState("")
    const [icon, setIcon] = createState("")
    const [visible, setVisible] = createState(false)

    let current: AstalHyprland.Client | null = null
    let titleHandler = 0

    function bindClient(client: AstalHyprland.Client | null) {
        if (current && titleHandler) {
            current.disconnect(titleHandler)
            titleHandler = 0
        }
        current = client
        if (client) {
            setVisible(true)
            setIcon(resolveIcon((client.class ?? "").toLowerCase()))
            setTitle(client.title ?? "")
            titleHandler = client.connect("notify::title", () =>
                setTitle(client.title ?? ""),
            )
        } else {
            setVisible(false)
            setIcon("")
            setTitle("")
        }
    }

    hypr.connect("notify::focused-client", () => bindClient(hypr.focusedClient))
    bindClient(hypr.focusedClient)

    return (
        <box class="active-window" visible={visible}>
            <image class="active-window-icon" iconName={icon} />
            <label
                class="active-window-title"
                label={title}
                maxWidthChars={32}
                ellipsize={Pango.EllipsizeMode.END}
            />
        </box>
    )
}
