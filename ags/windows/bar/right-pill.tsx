import { Gtk } from "ags/gtk4"
import { createBinding } from "ags"
import Tray from "./tray"
import Bluetooth from "./bluetooth"
import Network from "./network"
import Volume from "./volume"
import Cpu from "./cpu"
import NotificationBell from "./notifications"
import Battery from "./battery"
import { toggleQuickSettings, qsState } from "../quick-settings"

export default function RightPill() {
    return <box class="pill right-pill">
        <Tray />
        <box class={createBinding(qsState, "isOpen").as((open: boolean) =>
            open ? "qs-triggers qs-open" : "qs-triggers"
        )}>
            <Gtk.GestureClick onReleased={() => toggleQuickSettings()} />
            <Bluetooth />
            <Network />
            <Volume />
            <Battery />
        </box>
        <NotificationBell />
    </box>
}
