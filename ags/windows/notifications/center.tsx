import Pango from "gi://Pango"
import AstalNotifd from "gi://AstalNotifd"
import { For, createBinding, createComputed } from "ags"
import { Gtk } from "ags/gtk4"
import { glyph } from "../bar/glyphs"

let notifd: AstalNotifd.Notifd
const restoredIds = new Set<number>()
const popovers: Gtk.Popover[] = []

export function initCenter() {
    notifd = AstalNotifd.get_default()
    for (const n of notifd.get_notifications()) restoredIds.add(n.id)
}

export function toggleDnd() {
    if (notifd) notifd.dontDisturb = !notifd.dontDisturb
}

export function toggleCenter() {
    const pop = popovers[0]
    if (!pop) return
    if (pop.get_visible()) pop.popdown()
    else pop.popup()
}

function relTime(unixSeconds: number): string {
    const now = Math.floor(Date.now() / 1000)
    const d = Math.max(0, now - unixSeconds)
    if (d < 60) return "now"
    if (d < 3600) return `${Math.floor(d / 60)}m`
    if (d < 86400) return `${Math.floor(d / 3600)}h`
    return `${Math.floor(d / 86400)}d`
}

function clearAll() {
    for (const n of [...notifd.get_notifications()]) n.dismiss()
}

function HistoryCard(n: AstalNotifd.Notification) {
    const live = !restoredIds.has(n.id)
    return <box class="np-card" orientation={Gtk.Orientation.VERTICAL}>
        <box class="np-card-top">
            <box class="np-card-chip" valign={Gtk.Align.START}>
                <image class="np-card-icon" iconName={n.appIcon || "dialog-information-symbolic"} />
            </box>
            <box orientation={Gtk.Orientation.VERTICAL} hexpand>
                <box class="np-card-line">
                    <label
                        class="np-card-title"
                        hexpand
                        xalign={0}
                        maxWidthChars={28}
                        ellipsize={Pango.EllipsizeMode.END}
                        label={n.summary || ""}
                    />
                    <label class="np-card-time" valign={Gtk.Align.START} label={relTime(n.time)} />
                    <button class="np-card-close" valign={Gtk.Align.START} onClicked={() => n.dismiss()}>
                        <image iconName="window-close-symbolic" />
                    </button>
                </box>
                <label
                    class="np-card-body"
                    xalign={0}
                    wrap
                    wrapMode={Pango.WrapMode.WORD_CHAR}
                    maxWidthChars={32}
                    lines={3}
                    ellipsize={Pango.EllipsizeMode.END}
                    visible={(n.body || "") !== ""}
                    label={n.body || ""}
                />
            </box>
        </box>
        <box class="np-actions" visible={live && n.actions.length > 0}>
            {live ? n.actions.map(a => (
                <button class="np-action" onClicked={() => n.invoke(a.id)}>
                    <label label={a.label} />
                </button>
            )) : []}
        </box>
    </box>
}

export function NotificationPopover(): Gtk.Popover {
    const notifications = createBinding(notifd, "notifications")
    const sorted = createComputed(() => [...notifications()].sort((a, b) => b.time - a.time))
    const isEmpty = createComputed(() => notifications().length === 0)
    const hasItems = createComputed(() => notifications().length > 0)

    const content = (
        <box class="notifications-popover" orientation={Gtk.Orientation.VERTICAL}>
            <box class="np-header">
                <label class="np-title" hexpand xalign={0} label="Notifications" />
                <button class="np-clear" visible={hasItems} onClicked={() => clearAll()}>
                    <label label="Clear all" />
                </button>
            </box>
            <box class="np-empty" orientation={Gtk.Orientation.VERTICAL} visible={isEmpty}>
                <label class="np-empty-icon" label={glyph.bellSleepOutline} />
                <label class="np-empty-text" label="You're all caught up" />
            </box>
            <Gtk.ScrolledWindow
                class="np-scroll"
                vexpand
                hscrollbarPolicy={Gtk.PolicyType.NEVER}
                visible={hasItems}
            >
                <box class="np-list" orientation={Gtk.Orientation.VERTICAL}>
                    <For each={sorted}>
                        {(n: AstalNotifd.Notification) => HistoryCard(n)}
                    </For>
                </box>
            </Gtk.ScrolledWindow>
        </box>
    ) as Gtk.Widget

    const pop = new Gtk.Popover()
    pop.set_has_arrow(false)
    pop.add_css_class("popover-wrap")
    pop.set_child(content)
    popovers.push(pop)
    return pop
}
