import AstalNotifd from "gi://AstalNotifd"
import { createBinding } from "ags"
import { toggleCenter } from "../notifications/center"

export default function NotificationBell() {
    const notifd = AstalNotifd.get_default()
    const dnd = createBinding(notifd, "dontDisturb")
    const count = createBinding(notifd, "notifications").as(n => n.length)

    return <button class="notification-bell module-icon separator" onClicked={() => toggleCenter()}>
        <box>
            <image
                iconName={dnd.as((d: boolean) =>
                    d ? "notification-disabled-symbolic" : "notification-symbolic"
                )}
            />
            <label
                class="nc-badge"
                visible={count.as((c: number) => c > 0)}
                label={count.as((c: number) => String(c))}
            />
        </box>
    </button>
}
