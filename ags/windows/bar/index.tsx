import Gdk from "gi://Gdk"
import App from "ags/gtk4/app"
import { Astal } from "ags/gtk4"

import Tray from "./tray"
import Bluetooth from "./bluetooth"
import Network from "./network"
import Volume from "./volume"
import NotificationBell from "./notifications"
import Battery from "./battery"
import QuickSettings from "../QuickSettings/quick-settings"

import Clock from "./clock"
import Media from "./media"

import Workspaces from "./workspaces"
import Clients from "./clients"

export default function Bar(gdkmonitor: Gdk.Monitor) {
    return <window
        name="bar"
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
                  <Clients />
              </box>
            </box>
            <box $type="center">
              <box class="pill center-pill">
                  <Clock />
                  <Media />
              </box>
            </box>
            <box $type="end">
            <box class="pill right-pill">
              <Tray />
              <Bluetooth />
              <Network />
              <Volume />
              <Battery />
              <NotificationBell />
              <QuickSettings />
            </box>
          </box>
        </centerbox>
    </window>
}
