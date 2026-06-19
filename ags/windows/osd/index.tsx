import Gdk from "gi://Gdk"
import App from "ags/gtk4/app"
import { For, createBinding, createComputed } from "ags"
import { Astal, Gtk } from "ags/gtk4"

import {
    osdView,
    osdConnector,
    osdVolume,
    osdMedia,
} from "./controller"

function OsdWindow(gdkmonitor: Gdk.Monitor) {
    const myConnector = gdkmonitor.get_connector() ?? "unknown"

    const visible = createComputed(
        () => osdView() !== null && osdConnector() === myConnector,
    )

    return <window
        name={`osd-${myConnector}`}
        namespace="osd"
        application={App}
        gdkmonitor={gdkmonitor}
        class="osd"
        layer={Astal.Layer.OVERLAY}
        anchor={Astal.WindowAnchor.BOTTOM}
        exclusivity={Astal.Exclusivity.IGNORE}
        keymode={Astal.Keymode.NONE}
        marginBottom={80}
        visible={visible}
    >
        <box class="osd-content pill">
            <box
                class="osd-volume"
                visible={createComputed(() => osdView() === "volume")}
            >
                <image
                    class="osd-icon"
                    iconName={createComputed(() => osdVolume().icon)}
                />
                <Gtk.LevelBar
                    class="osd-level"
                    valign={Gtk.Align.CENTER}
                    value={createComputed(() => osdVolume().percent / 100)}
                />
                <label
                    class="osd-percent"
                    label={createComputed(() => `${osdVolume().percent}%`)}
                />
            </box>
            <box
                class="osd-media"
                visible={createComputed(() => osdView() === "media")}
            >
                <image
                    class="osd-icon osd-media-icon"
                    iconName={createComputed(() => osdMedia().icon)}
                />
                <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER} hexpand>
                    <label
                        class="osd-media-title"
                        xalign={0}
                        label={createComputed(() => osdMedia().title)}
                    />
                    <label
                        class="osd-media-artist"
                        xalign={0}
                        visible={createComputed(() => osdMedia().artist !== "")}
                        label={createComputed(() => osdMedia().artist)}
                    />
                </box>
                <image
                    class="osd-entry-icon"
                    valign={Gtk.Align.CENTER}
                    iconName={createComputed(() => osdMedia().entry)}
                />
            </box>
        </box>
    </window>
}

export default function Osd() {
    const monitors = createBinding(App, "monitors")
    return (
        <For each={monitors} cleanup={(win) => (win as Gtk.Window).destroy()}>
            {(monitor: Gdk.Monitor) => OsdWindow(monitor)}
        </For>
    )
}
