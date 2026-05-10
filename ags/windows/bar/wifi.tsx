import AstalNetwork from "gi://AstalNetwork"
import { createBinding } from "ags"

export default function Wifi() {
    const network = AstalNetwork.get_default()
    const wifi = network.wifi

    if (!wifi) {
        return <box class="wifi module-icon separator">
            <image iconName="network-wireless-offline-symbolic" />
        </box>
    }

    return <box
        class="wifi module-icon separator"
        tooltipText={createBinding(wifi, "ssid")}
    >
        <image iconName={createBinding(wifi, "iconName")} />
    </box>
}
