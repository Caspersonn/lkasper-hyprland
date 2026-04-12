import Tray from "./tray"
import Bluetooth from "./bluetooth"
import Wifi from "./wifi"
import Volume from "./volume"
import Cpu from "./cpu"
import NotificationBell from "./notifications"
import Battery from "./battery"

export default function RightPill() {
    return <box class="pill right-pill">
        <Tray />
        <Bluetooth />
        <Wifi />
        <Volume />
        <Cpu />
        <NotificationBell />
        <Battery />
    </box>
}
