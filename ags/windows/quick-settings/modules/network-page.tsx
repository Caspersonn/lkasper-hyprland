import { Gtk } from "ags/gtk4"
import { createBinding, createRoot, For } from "ags"
import { Page, PageButton } from "../widgets/page"
import { closeQuickSettings } from "../index"
import { exec } from "ags/process"
import AstalNetwork from "gi://AstalNetwork"

export const NetworkPage = createRoot((dispose) => new Page({
    id: "network",
    title: "Network",
    headerButtons: [{
        icon: "arrow-circular-top-right-symbolic",
        tooltipText: "Scan networks",
        actionClicked: () => {
            const wifi = AstalNetwork.get_default().wifi
            if (wifi) wifi.scan()
        },
    }],
    actionClosed: () => dispose(),
    bottomButtons: [{
        title: "More Settings",
        actionClicked: () => {
            closeQuickSettings()
            exec("nm-connection-editor")
        },
    }],
    content: () => {
        const network = AstalNetwork.get_default()
        const wifi = network.wifi

        return [
            // WiFi access points
            ...(wifi ? [
                <Gtk.Box class="wireless-aps" hexpand
                    orientation={Gtk.Orientation.VERTICAL} spacing={4}
                    visible={createBinding(network, "primary").as((p: number) =>
                        p === AstalNetwork.Primary.WIFI
                    )}>
                    <Gtk.Label class="sub-header" label="Wi-Fi" xalign={0} />
                    <For each={createBinding(wifi, "accessPoints")}>
                        {(ap: AstalNetwork.AccessPoint) =>
                            <PageButton
                                class={createBinding(wifi, "activeAccessPoint").as(
                                    (active: AstalNetwork.AccessPoint) =>
                                        active?.ssid === ap.ssid ? "active" : ""
                                )}
                                title={createBinding(ap, "ssid").as((s: string) => s ?? "Hidden Network")}
                                icon={createBinding(ap, "iconName")}
                                actionClicked={() => {
                                    // Connect to AP (works for open/saved networks)
                                    // For secured unsaved networks, NM will prompt
                                    if (wifi.activeAccessPoint?.ssid === ap.ssid) return
                                    // TODO: inline password entry for secured unsaved networks
                                    exec(`nmcli device wifi connect "${ap.ssid}"`)
                                }}
                                extraButtons={
                                    <Gtk.Button iconName="window-close-symbolic"
                                        visible={createBinding(wifi, "activeAccessPoint").as(
                                            (active: AstalNetwork.AccessPoint) =>
                                                active?.ssid === ap.ssid
                                        )}
                                        tooltipText="Disconnect"
                                        onClicked={() => {
                                            wifi.deactivate_connection(null)
                                        }} />
                                }
                            />
                        }
                    </For>
                </Gtk.Box>
            ] : []),
        ]
    },
}))
