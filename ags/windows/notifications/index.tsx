import Gdk from "gi://Gdk"
import App from "ags/gtk4/app"
import Pango from "gi://Pango"
import AstalNotifd from "gi://AstalNotifd"
import AstalHyprland from "gi://AstalHyprland"
import { For, createBinding, createComputed } from "ags"
import { Astal, Gtk } from "ags/gtk4"

import { activePopups } from "./popups"

const hypr = AstalHyprland.get_default()

function urgencyClass(n: AstalNotifd.Notification): string {
    switch (n.urgency) {
        case AstalNotifd.Urgency.CRITICAL:
            return "urgency-critical"
        case AstalNotifd.Urgency.LOW:
            return "urgency-low"
        default:
            return "urgency-normal"
    }
}

function NotifIcon(n: AstalNotifd.Notification) {
    const img = n.image
    if (img && img.startsWith("/")) {
        return <image class="notification-image" file={img} pixelSize={48} />
    }
    return (
        <image
            class="notification-icon"
            iconName={img || n.appIcon || "dialog-information-symbolic"}
        />
    )
}

function Card(n: AstalNotifd.Notification) {
    return <box class={`notification ${urgencyClass(n)}`} orientation={Gtk.Orientation.VERTICAL}>
        <box class="notification-header">
            {NotifIcon(n)}
            <box orientation={Gtk.Orientation.VERTICAL} hexpand valign={Gtk.Align.CENTER}>
                <label
                    class="notification-summary"
                    xalign={0}
                    maxWidthChars={36}
                    ellipsize={Pango.EllipsizeMode.END}
                    label={n.summary || ""}
                />
                <label
                    class="notification-body"
                    xalign={0}
                    wrap
                    wrapMode={Pango.WrapMode.WORD_CHAR}
                    maxWidthChars={36}
                    lines={4}
                    ellipsize={Pango.EllipsizeMode.END}
                    visible={(n.body || "") !== ""}
                    label={n.body || ""}
                />
            </box>
            <button
                class="notification-close"
                valign={Gtk.Align.START}
                onClicked={() => n.dismiss()}
            >
                <image iconName="window-close-symbolic" />
            </button>
        </box>
        <box class="notification-actions" homogeneous visible={n.actions.length > 0}>
            {n.actions.map(a => (
                <button class="notification-action" onClicked={() => n.invoke(a.id)}>
                    <label label={a.label} />
                </button>
            ))}
        </box>
    </box>
}

function PopupWindow(gdkmonitor: Gdk.Monitor) {
    const myConnector = gdkmonitor.get_connector() ?? "unknown"
    const focused = createBinding(hypr, "focusedMonitor")

    const visible = createComputed(() => {
        const fm = focused()
        return (fm?.name ?? null) === myConnector && activePopups().length > 0
    })

    return <window
        name={`notifications-${myConnector}`}
        namespace="notifications"
        application={App}
        gdkmonitor={gdkmonitor}
        class="notification-popups"
        layer={Astal.Layer.OVERLAY}
        anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
        exclusivity={Astal.Exclusivity.NORMAL}
        keymode={Astal.Keymode.NONE}
        marginTop={8}
        marginRight={8}
        visible={visible}
    >
        <box orientation={Gtk.Orientation.VERTICAL}>
            <For each={activePopups}>
                {(n: AstalNotifd.Notification) => Card(n)}
            </For>
        </box>
    </window>
}

export default function NotificationPopups() {
    const monitors = createBinding(App, "monitors")
    return (
        <For each={monitors} cleanup={(win) => (win as Gtk.Window).destroy()}>
            {(monitor: Gdk.Monitor) => PopupWindow(monitor)}
        </For>
    )
}
