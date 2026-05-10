import AstalNetwork from "gi://AstalNetwork"
import { createBinding, createComputed } from "ags"

export default function Network() {
    const network = AstalNetwork.get_default()
    const primary = createBinding(network, "primary")
    const wifi = network.wifi
    const wired = network.wired

    const icon = createComputed([
        primary,
        ...(wifi ? [createBinding(wifi, "iconName")] : []),
        ...(wired ? [createBinding(wired, "iconName")] : []),
    ], (p: number, ...rest: any[]) => {
        if (p === AstalNetwork.Primary.WIFI && rest[0]) return rest[0]
        if (p === AstalNetwork.Primary.WIRED && rest[wifi ? 1 : 0]) return rest[wifi ? 1 : 0]
        return "network-offline-symbolic"
    })

    const tooltip = createComputed([
        primary,
        ...(wifi ? [createBinding(wifi, "ssid")] : []),
    ], (p: number, ...rest: any[]) => {
        if (p === AstalNetwork.Primary.WIFI && rest[0]) return rest[0] as string
        if (p === AstalNetwork.Primary.WIRED) return "Wired"
        return "Disconnected"
    })

    const cssClass = createComputed([
        primary,
        ...(wifi ? [createBinding(wifi, "internet")] : []),
        ...(wired ? [createBinding(wired, "internet")] : []),
    ], (p: number, ...rest: any[]) => {
        const inet = p === AstalNetwork.Primary.WIFI
            ? rest[0]
            : rest[wifi ? 1 : 0]
        const base = "network module-icon separator"
        return inet === AstalNetwork.Internet.DISCONNECTED
            ? `${base} disconnected`
            : base
    })

    return <box class={cssClass} tooltipText={tooltip}>
        <image iconName={icon} />
    </box>
}
