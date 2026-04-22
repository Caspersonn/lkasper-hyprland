import { Tile } from "../widgets/tile"
import { tilesPages } from "../tiles"
import { NetworkPage } from "./network-page"
import { createBinding, createComputed } from "ags"
import AstalNetwork from "gi://AstalNetwork"
import { exec } from "ags/process"

const { WIFI, WIRED } = AstalNetwork.Primary
const { CONNECTED, CONNECTING, DISCONNECTED } = AstalNetwork.Internet

function safeBinding<T>(parent: any, child: string, prop: string, fallback: T) {
    return createBinding(parent, child).as((c: any) =>
        c ? createBinding(c, prop) : fallback
    )
}

export function NetworkTile(): Tile {
    const network = AstalNetwork.get_default()
    const wifi = network.wifi
    const wired = network.wired

    const primary = createBinding(network, "primary")

    const wifiInternet = wifi
        ? createBinding(wifi, "internet")
        : DISCONNECTED

    const wiredInternet = wired
        ? createBinding(wired, "internet")
        : DISCONNECTED

    return <Tile
        hasArrow
        title={createComputed([
            primary,
            ...(wifi ? [createBinding(wifi, "internet"), createBinding(wifi, "ssid")] : [])
        ], (p: number, ...rest: any[]) => {
            const wiInternet = rest[0]
            const wiSSID = rest[1]
            if (p === WIFI && wiInternet === CONNECTED && wiSSID) return wiSSID
            if (p === WIFI) return "WiFi"
            if (p === WIRED) return "Wired"
            return "Network"
        })}
        icon={createComputed([
            primary,
            ...(wifi ? [createBinding(wifi, "iconName")] : []),
            ...(wired ? [createBinding(wired, "iconName")] : [])
        ], (p: number, ...rest: any[]) => {
            if (p === WIFI && rest[0]) return rest[0]
            if (p === WIRED && rest[wifi ? 1 : 0]) return rest[wifi ? 1 : 0]
            return "network-wired-no-route-symbolic"
        })}
        state={createComputed([
            primary,
            ...(wifi ? [createBinding(wifi, "enabled")] : []),
            ...(wired ? [wiredInternet] : [])
        ], (p: number, ...rest: any[]) => {
            if (p === WIFI) return !!rest[0]
            if (p === WIRED) return rest[wifi ? 1 : 0] === CONNECTED || rest[wifi ? 1 : 0] === CONNECTING
            return false
        })}
        description={createComputed([
            primary,
            ...(wifi ? [createBinding(wifi, "internet")] : []),
            ...(wired ? [wiredInternet] : [])
        ], (p: number, ...rest: any[]) => {
            const inet = p === WIFI ? rest[0] : rest[wifi ? 1 : 0]
            if (inet === CONNECTED) return "Connected"
            if (inet === CONNECTING) return "Connecting..."
            return "Disconnected"
        })}
        onToggled={(_self: Tile, state: boolean) => {
            if (network.primary === WIFI && wifi) {
                wifi.set_enabled(state)
            } else if (network.primary === WIRED) {
                exec(state ? "nmcli n on" : "nmcli n off").catch(() => {})
            }
        }}
        onClicked={() => tilesPages?.toggle(NetworkPage)}
    /> as Tile
}
