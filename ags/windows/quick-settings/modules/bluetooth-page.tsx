import { Gtk } from "ags/gtk4"
import { createBinding, createComputed, createRoot, For } from "ags"
import { Page, PageButton } from "../widgets/page"
import { closeQuickSettings } from "../index"
import { exec } from "ags/process"
import AstalBluetooth from "gi://AstalBluetooth"

export const BluetoothPage = createRoot((dispose) => new Page({
    id: "bluetooth",
    title: "Bluetooth",
    description: "Manage devices",
    spacing: 6,
    headerButtons: [{
        icon: createBinding(AstalBluetooth.get_default(), "adapter").as((adapter: AstalBluetooth.Adapter | null) =>
            adapter?.discovering
                ? "media-playback-stop-symbolic"
                : "arrow-circular-top-right-symbolic"
        ),
        tooltipText: "Toggle discovery",
        actionClicked: () => {
            const adapter = AstalBluetooth.get_default().adapter
            if (!adapter) return
            adapter.discovering ? adapter.stop_discovery() : adapter.start_discovery()
        },
    }],
    actionClosed: () => {
        dispose()
        const adapter = AstalBluetooth.get_default().adapter
        if (adapter?.discovering) adapter.stop_discovery()
    },
    bottomButtons: [{
        title: "More Settings",
        actionClicked: () => {
            closeQuickSettings()
            exec("blueman-manager")
        },
    }],
    content: () => {
        const bt = AstalBluetooth.get_default()
        const devices = createBinding(bt, "devices")
        const knownDevices = devices.as((devs: AstalBluetooth.Device[]) =>
            devs.filter(d => d.trusted || d.paired || d.connected)
        )
        const discoveredDevices = devices.as((devs: AstalBluetooth.Device[]) =>
            devs.filter(d => !d.trusted && !d.paired && !d.connected)
        )

        return [
            <Gtk.Box class="paired" orientation={Gtk.Orientation.VERTICAL} spacing={4}
                visible={knownDevices.as((devs: AstalBluetooth.Device[]) => devs.length > 0)}>
                <Gtk.Label class="sub-header" label="Devices" xalign={0} />
                <For each={knownDevices}>
                    {(dev: AstalBluetooth.Device) => <DeviceWidget device={dev} />}
                </For>
            </Gtk.Box>,
            <Gtk.Box class="discovered" orientation={Gtk.Orientation.VERTICAL} spacing={4}
                visible={discoveredDevices.as((devs: AstalBluetooth.Device[]) => devs.length > 0)}>
                <Gtk.Label class="sub-header" label="New Devices" xalign={0} />
                <For each={discoveredDevices}>
                    {(dev: AstalBluetooth.Device) => <DeviceWidget device={dev} />}
                </For>
            </Gtk.Box>,
        ]
    },
}))

function DeviceWidget({ device }: { device: AstalBluetooth.Device }): Gtk.Widget {
    return <PageButton
        class={createBinding(device, "connected").as((c: boolean) => c ? "selected" : "")}
        title={createBinding(device, "alias").as((a: string) => a ?? "Unknown Device")}
        icon={createBinding(device, "icon").as((i: string) => i ?? "bluetooth-active-symbolic")}
        actionClicked={() => {
            if (device.connected) return
            if (!device.paired) {
                device.pair()
                device.set_trusted(true)
            }
            device.connect_device(null)
        }}
        endWidget={
            <Gtk.Box spacing={4}
                visible={createBinding(device, "connected")}>
                <Gtk.Label halign={Gtk.Align.END}
                    label={createBinding(device, "batteryPercentage").as((b: number) =>
                        b > 0 ? `${Math.floor(b * 100)}%` : ""
                    )} />
            </Gtk.Box>
        }
        extraButtons={
            <Gtk.Box visible={createComputed([
                createBinding(device, "connected"),
                createBinding(device, "trusted")
            ]).as(([c, t]: [boolean, boolean]) => c || t)}>
                <Gtk.Button
                    iconName={createBinding(device, "connected").as((c: boolean) =>
                        c ? "list-remove-symbolic" : "user-trash-symbolic"
                    )}
                    tooltipText={createBinding(device, "connected").as((c: boolean) =>
                        c ? "Disconnect" : "Forget"
                    )}
                    onClicked={() => {
                        if (device.connected) {
                            device.disconnect_device(null)
                        } else {
                            AstalBluetooth.get_default().adapter?.remove_device(device)
                        }
                    }} />
            </Gtk.Box>
        }
    /> as Gtk.Widget
}
