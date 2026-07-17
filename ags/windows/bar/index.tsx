import Gdk from "gi://Gdk"
import App from "ags/gtk4/app"
import { For, createBinding } from "ags"
import { Astal, Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"

import Workspaces from "./workspaces"
import { Launcher } from "./../launcher"
import ActiveWindow from "./active-window"
import Clock from "./clock"
import Media from "./media"
import Weather from "./weather"
import SystemStats from "./system-stats"
import Tray from "./tray"
import QuickControls from "./quick-controls"
import NotificationBell from "./notifications"
import PowerButton from "./power"

function Divider({ wide = false }: { wide?: boolean }) {
    return <box class={wide ? "island-divider wide" : "island-divider"} valign={Gtk.Align.CENTER} />
}

function Bar(gdkmonitor: Gdk.Monitor, name: string) {
    return <window
        name={name}
        namespace="bar"
        application={App}
        gdkmonitor={gdkmonitor}
        class="bar"
        anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        visible
    >
        <centerbox class="bar-inner">
            <box $type="start">
                <box class="island left-island">
                    <Launcher />
                    <Divider />
                    <Workspaces />
                    <Divider />
                    <ActiveWindow />
                </box>
            </box>
            <box $type="center">
                <Clock />
            </box>
            <box $type="end">
                <box class="island right-island">
                    <Media />
                    <Divider />
                    <Weather />
                    <Divider />
                    <SystemStats />
                    <Divider />
                    <Tray />
                    <Divider />
                    <QuickControls />
                    <Divider wide />
                    <NotificationBell />
                    <Divider />
                    <PowerButton />
                </box>
            </box>
        </centerbox>
    </window>
}

export default function Bars() {
    const monitors = createBinding(App, "monitors")
    return (
        <For each={monitors} cleanup={(win) => (win as Gtk.Window).destroy()}>
            {(monitor: Gdk.Monitor) =>
                Bar(monitor, `bar-${monitor.get_connector() ?? "unknown"}`)
            }
        </For>
    )
}
