import AstalMpris from "gi://AstalMpris"
import Pango from "gi://Pango"
import { Gtk } from "ags/gtk4"
import { createComputed, createState, Accessor } from "ags"
import { createPoll } from "ags/time"
import { glyph } from "./glyphs"

const mpris = AstalMpris.Mpris.get_default()

const fmt = (sec: number) => {
    const s = Math.max(0, Math.floor(sec))
    return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`
}

type PopoverProps = {
    title: Accessor<string>
    artist: Accessor<string>
    album: Accessor<string>
    fraction: Accessor<number>
    elapsedLabel: Accessor<string>
    totalLabel: Accessor<string>
    playIcon: Accessor<string>
    onSeek: (v: number) => void
    onPlayPause: () => void
    onNext: () => void
    onPrev: () => void
    onShuffle: () => void
    onRepeat: () => void
}

function MediaPopover(p: PopoverProps): Gtk.Popover {
    const content = (
        <box class="media-popover" orientation={Gtk.Orientation.VERTICAL}>
            <box class="mp-top">
                <box class="mp-art" valign={Gtk.Align.CENTER}>
                    <label class="mp-art-icon" label={glyph.music} />
                </box>
                <box
                    class="mp-meta"
                    orientation={Gtk.Orientation.VERTICAL}
                    valign={Gtk.Align.CENTER}
                    hexpand
                >
                    <label class="mp-now" label="NOW PLAYING" halign={Gtk.Align.START} />
                    <label
                        class="mp-title"
                        label={p.title}
                        maxWidthChars={20}
                        ellipsize={Pango.EllipsizeMode.END}
                        halign={Gtk.Align.START}
                    />
                    <label class="mp-artist" label={p.artist} halign={Gtk.Align.START} />
                    <label class="mp-album" label={p.album} halign={Gtk.Align.START} />
                </box>
            </box>
            <slider
                class="mp-seek"
                hexpand
                value={p.fraction}
                onChangeValue={(self: Gtk.Scale) => p.onSeek(self.value)}
            />
            <box class="mp-times">
                <label class="mp-elapsed" label={p.elapsedLabel} hexpand halign={Gtk.Align.START} />
                <label class="mp-total" label={p.totalLabel} halign={Gtk.Align.END} />
            </box>
            <box class="mp-controls" halign={Gtk.Align.CENTER}>
                <button class="mp-ctl" onClicked={() => p.onShuffle()}>
                    <label label={glyph.shuffle} />
                </button>
                <button class="mp-ctl mp-ctl-lg" onClicked={() => p.onPrev()}>
                    <label label={glyph.skipPrevious} />
                </button>
                <button class="mp-play" onClicked={() => p.onPlayPause()}>
                    <label label={p.playIcon} />
                </button>
                <button class="mp-ctl" onClicked={() => p.onNext()}>
                    <label label={glyph.skipNext} />
                </button>
                <button class="mp-ctl" onClicked={() => p.onRepeat()}>
                    <label label={glyph.repeat} />
                </button>
            </box>
        </box>
    ) as Gtk.Widget

    const pop = new Gtk.Popover()
    pop.set_has_arrow(false)
    pop.add_css_class("popover-wrap")
    pop.set_child(content)
    return pop
}

export default function Media() {
    const [visible, setVisible] = createState(false)
    const [title, setTitle] = createState("")
    const [artist, setArtist] = createState("")
    const [album, setAlbum] = createState("")
    const [length, setLength] = createState(0)
    const [playing, setPlaying] = createState(false)
    let current: AstalMpris.Player | null = null
    let handlers: number[] = []

    function sync(player: AstalMpris.Player | null) {
        setVisible(!!player)
        setTitle(player?.title || "Unknown")
        setArtist(player?.artist || "")
        setAlbum(player?.album || "")
        setLength(player && player.length > 0 ? player.length : 0)
        setPlaying(player?.playbackStatus === AstalMpris.PlaybackStatus.PLAYING)
    }

    function pickPlayer() {
        const players = (mpris.players ?? []) as AstalMpris.Player[]
        return (
            players.find((p) => p.playbackStatus === AstalMpris.PlaybackStatus.PLAYING) ??
            players[0] ??
            null
        )
    }

    function bindPlayer(player: AstalMpris.Player | null) {
        if (current) {
            handlers.forEach((h) => current?.disconnect(h))
            handlers = []
        }
        current = player
        if (player) {
            handlers = [
                player.connect("notify::title", () => sync(player)),
                player.connect("notify::artist", () => sync(player)),
                player.connect("notify::album", () => sync(player)),
                player.connect("notify::length", () => sync(player)),
                player.connect("notify::playback-status", () => sync(player)),
            ]
        }
        sync(player)
    }

    mpris.connect("player-added", () => bindPlayer(pickPlayer()))
    mpris.connect("player-closed", () => bindPlayer(pickPlayer()))
    bindPlayer(pickPlayer())

    const position = createPoll(0, 1000, () => current?.position ?? 0)
    const fraction = createComputed([length, position], (l, p) => (l > 0 && p > 0 ? p / l : 0))
    const elapsedLabel = position.as((p: number) => fmt(p))
    const totalLabel = length.as((l: number) => fmt(l))
    const eqClass = createComputed([playing], (pl) =>
        pl ? ["media-eq", "playing"] : ["media-eq"],
    )
    const playIcon = createComputed([playing], (pl) => (pl ? glyph.pause : glyph.play))
    const popover = MediaPopover({
        title,
        artist,
        album,
        fraction,
        elapsedLabel,
        totalLabel,
        playIcon,
        onSeek: (v) => {
            if (current && length.get() > 0) current.set_position(v * length.get())
        },
        onPlayPause: () => current?.play_pause(),
        onNext: () => current?.next(),
        onPrev: () => current?.previous(),
        onShuffle: () => current?.shuffle(),
        onRepeat: () => current?.loop(),
    })

    return (
        <button
            class="media island-sub"
            visible={visible}
            $={(self: Gtk.Button) => popover.set_parent(self)}
            onClicked={() => popover.popup()}
        >
            <box class="media-inner">
                <box class="media-art" valign={Gtk.Align.CENTER}>
                    <label class="media-art-icon" label={glyph.music} />
                </box>
                <box
                    class="media-meta"
                    orientation={Gtk.Orientation.VERTICAL}
                    valign={Gtk.Align.CENTER}
                >
                    <label
                        class="media-title"
                        label={title}
                        maxWidthChars={14}
                        ellipsize={Pango.EllipsizeMode.END}
                        halign={Gtk.Align.START}
                    />
                    <label
                        class="media-artist"
                        label={artist}
                        maxWidthChars={14}
                        ellipsize={Pango.EllipsizeMode.END}
                        halign={Gtk.Align.START}
                    />
                </box>
                <box cssClasses={eqClass} valign={Gtk.Align.CENTER}>
                    <box class="eq-bar eq-bar-1" valign={Gtk.Align.END} />
                    <box class="eq-bar eq-bar-2" valign={Gtk.Align.END} />
                    <box class="eq-bar eq-bar-3" valign={Gtk.Align.END} />
                </box>
            </box>
        </button>
    )
}
