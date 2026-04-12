import AstalBluetooth from "gi://AstalBluetooth"
import { createBinding } from "ags"

export default function Bluetooth() {
    const bt = AstalBluetooth.get_default()

    return <box
        class={createBinding(bt, "isPowered").as(p =>
            p
                ? "bluetooth module-icon separator"
                : "bluetooth module-icon separator disabled"
        )}
        tooltipText={createBinding(bt, "devices").as(devices => {
            const connected = devices.filter(d => d.connected)
            return connected.length > 0
                ? `${connected.length} device${connected.length > 1 ? "s" : ""} connected`
                : "No devices connected"
        })}
    >
        <image iconName={createBinding(bt, "isPowered").as(p =>
            p ? "bluetooth-active-symbolic" : "bluetooth-disabled-symbolic"
        )} />
    </box>
}
