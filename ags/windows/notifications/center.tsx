import Pango from "gi://Pango"
import App from "ags/gtk4/app"
import AstalNotifd from "gi://AstalNotifd"
import AstalMpris from "gi://AstalMpris"
import { For, createState, createBinding, createComputed } from "ags"
import { Astal, Gtk } from "ags/gtk4"

let notifd: AstalNotifd.Notifd
const restoredIds = new Set<number>()

const [centerVisible, setCenterVisible] = createState(false)
export { centerVisible }

export function toggleCenter() {
    setCenterVisible(!centerVisible())
}

export function toggleDnd() {
    if (notifd) notifd.dontDisturb = !notifd.dontDisturb
}

export function initCenter() {
    notifd = AstalNotifd.get_default()
    for (const n of notifd.get_notifications()) restoredIds.add(n.id)
}

function relTime(unixSeconds: number): string {
    const now = Math.floor(Date.now() / 1000)
    const d = Math.max(0, now - unixSeconds)
    if (d < 60) return "now"
    if (d < 3600) return `${Math.floor(d / 60)}m`
    if (d < 86400) return `${Math.floor(d / 3600)}h`
    return `${Math.floor(d / 86400)}d`
}

interface Group {
    app: string
    items: AstalNotifd.Notification[]
}

function groupByApp(list: AstalNotifd.Notification[]): Group[] {
    const sorted = [...list].sort((a, b) => b.time - a.time) // newest first
    const map = new Map<string, AstalNotifd.Notification[]>()
    for (const n of sorted) {
        const app = n.appName || "Notifications"
        if (!map.has(app)) map.set(app, [])
        map.get(app)!.push(n)
    }
    return Array.from(map, ([app, items]) => ({ app, items }))
}

function HistoryCard(n: AstalNotifd.Notification) {
    const live = !restoredIds.has(n.id)
    return <box class="nc-card" orientation={Gtk.Orientation.VERTICAL}>
        <box class="nc-card-header">
            <image class="nc-card-icon" iconName={n.appIcon || "dialog-information-symbolic"} />
            <box orientation={Gtk.Orientation.VERTICAL} hexpand valign={Gtk.Align.CENTER}>
                <label
                    class="nc-card-summary"
                    xalign={0}
                    maxWidthChars={30}
                    ellipsize={Pango.EllipsizeMode.END}
                    label={n.summary || ""}
                />
                <label
                    class="nc-card-body"
                    xalign={0}
                    wrap
                    wrapMode={Pango.WrapMode.WORD_CHAR}
                    maxWidthChars={30}
                    lines={3}
                    ellipsize={Pango.EllipsizeMode.END}
                    visible={(n.body || "") !== ""}
                    label={n.body || ""}
                />
            </box>
            <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.START}>
                <label class="nc-card-time" label={relTime(n.time)} />
                <button class="nc-card-close" halign={Gtk.Align.END} onClicked={() => n.dismiss()}>
                    <image iconName="window-close-symbolic" />
                </button>
            </box>
        </box>
        <box class="nc-card-actions" visible={live && n.actions.length > 0}>
            {live ? n.actions.map(a => (
                <button class="nc-action" onClicked={() => n.invoke(a.id)}>
                    <label label={a.label} />
                </button>
            )) : []}
        </box>
    </box>
}

function CenterMedia() {
    const mpris = AstalMpris.get_default()
    const PLAYING = AstalMpris.PlaybackStatus.PLAYING
    const PAUSED = AstalMpris.PlaybackStatus.PAUSED

    const [title, setTitle] = createState("")
    const [artist, setArtist] = createState("")
    const [icon, setIcon] = createState("audio-x-generic-symbolic")
    const [visible, setVisible] = createState(false)
    let active: AstalMpris.Player | null = null

    function isRelevant(p: AstalMpris.Player) {
        return p.busName != null && !p.busName.includes("playerctld")
    }
    function pickBest(): AstalMpris.Player | null {
        const list = mpris.get_players().filter(isRelevant)
        return list.find(p => p.playbackStatus === PLAYING)
            ?? list.find(p => p.playbackStatus === PAUSED)
            ?? null
    }
    function update() {
        active = pickBest()
        setTitle(active?.title || "")
        setArtist(active?.artist || "")
        setIcon(active?.entry || "audio-x-generic-symbolic")
        setVisible(active != null)
    }
    function watch(p: AstalMpris.Player) {
        p.connect("notify::playback-status", update)
        p.connect("notify::title", () => {
            if (p === active) {
                setTitle(p.title || "")
                setArtist(p.artist || "")
            }
        })
    }
    for (const p of mpris.get_players()) if (isRelevant(p)) watch(p)
    mpris.connect("player-added", (_: any, p: AstalMpris.Player) => {
        if (isRelevant(p)) { watch(p); update() }
    })
    mpris.connect("player-closed", () => update())
    update()

    return <box class="nc-media" visible={visible}>
        <image class="nc-media-icon" iconName={icon} />
        <box orientation={Gtk.Orientation.VERTICAL} hexpand valign={Gtk.Align.CENTER}>
            <label class="nc-media-title" xalign={0} maxWidthChars={26} ellipsize={Pango.EllipsizeMode.END} label={title} />
            <label
                class="nc-media-artist"
                xalign={0}
                maxWidthChars={26}
                ellipsize={Pango.EllipsizeMode.END}
                visible={createComputed(() => artist() !== "")}
                label={artist}
            />
        </box>
        <button class="nc-media-btn" onClicked={() => active?.previous()}>
            <image iconName="media-skip-backward-symbolic" />
        </button>
        <button class="nc-media-btn" onClicked={() => active?.play_pause()}>
            <image iconName="media-playback-start-symbolic" />
        </button>
        <button class="nc-media-btn" onClicked={() => active?.next()}>
            <image iconName="media-skip-forward-symbolic" />
        </button>
    </box>
}

function clearAll() {
    for (const n of [...notifd.get_notifications()]) n.dismiss()
}

export default function NotificationCenter() {
    const notifications = createBinding(notifd, "notifications")
    const dnd = createBinding(notifd, "dontDisturb")
    const groups = createComputed(() => groupByApp(notifications()))
    const isEmpty = createComputed(() => notifications().length === 0)

    return <window
        name="notification-center"
        namespace="notification-center"
        application={App}
        class="notification-center"
        layer={Astal.Layer.OVERLAY}
        anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT}
        exclusivity={Astal.Exclusivity.NORMAL}
        keymode={Astal.Keymode.NONE}
        visible={centerVisible}
    >
        <box>
            <box class="nc-backdrop" hexpand>
                <Gtk.GestureClick onPressed={() => toggleCenter()} />
            </box>
            <box class="nc-panel" orientation={Gtk.Orientation.VERTICAL} hexpand={false}>
                <box class="nc-header">
                    <togglebutton class="nc-dnd" active={dnd} onClicked={() => toggleDnd()}>
                        <label label="Do Not Disturb" />
                    </togglebutton>
                    <box hexpand />
                    <button class="nc-clear" onClicked={() => clearAll()}>
                        <label label="Clear All" />
                    </button>
                </box>

                <CenterMedia />

                <Gtk.ScrolledWindow vexpand hscrollbarPolicy={Gtk.PolicyType.NEVER}>
                    <box class="nc-history" orientation={Gtk.Orientation.VERTICAL}>
                        <label class="nc-empty" label="No notifications" visible={isEmpty} />
                        <box
                            orientation={Gtk.Orientation.VERTICAL}
                            visible={createComputed(() => !isEmpty())}
                        >
                            <For each={groups}>
                                {(g: Group) => (
                                    <box class="nc-group" orientation={Gtk.Orientation.VERTICAL}>
                                        <label
                                            class="nc-group-header"
                                            xalign={0}
                                            label={`${g.app} (${g.items.length})`}
                                        />
                                        {g.items.map(n => HistoryCard(n))}
                                    </box>
                                )}
                            </For>
                        </box>
                    </box>
                </Gtk.ScrolledWindow>
            </box>
        </box>
    </window>
}
