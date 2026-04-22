import { Tile } from "../widgets/tile"
import { tilesPages } from "../tiles"
import { BluetoothPage } from "./bluetooth-page"
import { createBinding, createComputed } from "ags"
import AstalBluetooth from "gi://AstalBluetooth"

export function BluetoothTile(): Tile {
    const bt = AstalBluetooth.get_default()

    return <Tile
        hasArrow
        title={createBinding(bt, "devices").as((devices: AstalBluetooth.Device[]) => {
            const connected = devices.find(d => d.connected)
            return connected?.alias ?? "Bluetooth"
        })}
        description={createBinding(bt, "devices").as((devices: AstalBluetooth.Device[]) => {
            const connected = devices.find(d => d.connected)
            if (!connected) return ""
            const batt = connected.batteryPercentage
            if (batt > 0) return `Battery: ${Math.floor(batt * 100)}%`
            return "Connected"
        })}
        visible={createBinding(bt, "adapter").as((a: AstalBluetooth.Adapter | null) => a !== null)}
        state={createBinding(bt, "isPowered")}
        icon={createComputed([
            createBinding(bt, "isPowered"),
            createBinding(bt, "isConnected")
        ], (powered: boolean, connected: boolean) =>
            powered
                ? connected
                    ? "bluetooth-active-symbolic"
                    : "bluetooth-symbolic"
                : "bluetooth-disabled-symbolic"
        )}
        onEnabled={() => {
            const adapter = bt.adapter
            if (adapter) adapter.set_powered(true)
        }}
        onDisabled={() => {
            const adapter = bt.adapter
            if (adapter) adapter.set_powered(false)
        }}
        onClicked={() => tilesPages?.toggle(BluetoothPage)}
    /> as Tile
}
