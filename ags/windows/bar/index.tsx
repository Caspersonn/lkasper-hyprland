import Gdk from "gi://Gdk"
import App from "ags/gtk4/app"
import { For, createBinding } from "ags"
import { Astal, Gtk } from "ags/gtk4"

import Tray from "./tray"
import Bluetooth from "./bluetooth"
import Network from "./network"
import Volume from "./volume"
import NotificationBell from "./notifications"
import Battery from "./battery"
import QuickSettings from "../quicksettings/quick-settings"

import Clock from "./clock"
import Media from "./media"

import Workspaces from "./workspaces"

function Bar(gdkmonitor: Gdk.Monitor, name: string) {
    return <window
        name={name}
        namespace="bar"
        application={App}
        gdkmonitor={gdkmonitor}
        class="bar"
        anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        marginTop={8}
        marginLeft={8}
        marginRight={8}
        visible
    >
        <centerbox>
            <box $type="start">
              <box class="pill left-pill">
                  <Workspaces />
              </box>
            </box>
            <box $type="center">
              <box class="pill center-pill">
                  <Clock />
              </box>
            </box>
            <box $type="end">
            <box class="pill right-pill">
              <Tray />
              <Bluetooth />
              <Network />
              <Volume />
              <Battery />
              <QuickSettings />
              <NotificationBell />
            </box>
          </box>
        </centerbox>
    </window>
}

// Reactively maintain one bar per monitor. `For` is driven by the App's
// `monitors` property (which fires on Gdk monitor add/remove), creating a bar
// for each new monitor and running `cleanup` to destroy the window of a
// monitor that is unplugged. This delegates the GTK4 window lifecycle to the
// framework, which is required for reliable hot-plug/replug handling.
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
