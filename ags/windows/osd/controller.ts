import GLib from "gi://GLib"
import AstalWp from "gi://AstalWp"
import AstalMpris from "gi://AstalMpris"
import AstalHyprland from "gi://AstalHyprland"
import { createState } from "ags"

export type OsdView = "volume" | "media" | null

export interface VolumeData {
    percent: number
    mute: boolean
    icon: string
}

export interface MediaData {
    title: string
    artist: string
    icon: string
    entry: string
}

const OSD_TIMEOUT_MS = 1500
const READY_DELAY_MS = 1000

const PLAY_ICON = "media-playback-start-symbolic"
const PAUSE_ICON = "media-playback-pause-symbolic"
const NEXT_ICON = "media-skip-forward-symbolic"
const PREV_ICON = "media-skip-backward-symbolic"

const [view, setView] = createState<OsdView>(null)
const [connector, setConnector] = createState<string | null>(null)
const [volume, setVolume] = createState<VolumeData>({
    percent: 0,
    mute: false,
    icon: "audio-volume-muted-symbolic",
})
const [media, setMedia] = createState<MediaData>({
    title: "",
    artist: "",
    icon: PLAY_ICON,
    entry: "audio-x-generic-symbolic",
})

export const osdView = view
export const osdConnector = connector
export const osdVolume = volume
export const osdMedia = media

let ready = false
let timerId: number | null = null

const hypr = AstalHyprland.get_default()

function armTimer() {
    if (timerId !== null) {
        GLib.source_remove(timerId)
        timerId = null
    }
    timerId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, OSD_TIMEOUT_MS, () => {
        setView(null)
        timerId = null
        return GLib.SOURCE_REMOVE
    })
}

function present(v: OsdView) {
    if (!ready) return
    const fm = hypr.focusedMonitor
    setConnector(fm ? fm.name : null)
    setView(v)
    armTimer()
}

const wp = AstalWp.get_default()

function speakerData(speaker: AstalWp.Endpoint): VolumeData {
    return {
        percent: Math.round((speaker.volume ?? 0) * 100),
        mute: speaker.mute ?? false,
        icon: speaker.volumeIcon ?? "audio-volume-high-symbolic",
    }
}

let watchedSpeaker: AstalWp.Endpoint | null = null

function watchDefaultSpeaker() {
    const speaker = wp?.audio?.defaultSpeaker
    if (!speaker || speaker === watchedSpeaker) return
    watchedSpeaker = speaker
    speaker.connect("notify::volume", () => {
        setVolume(speakerData(speaker))
        present("volume")
    })
    speaker.connect("notify::mute", () => {
        setVolume(speakerData(speaker))
        present("volume")
    })
}

const mpris = AstalMpris.get_default()
const PLAYING = AstalMpris.PlaybackStatus.PLAYING
const PAUSED = AstalMpris.PlaybackStatus.PAUSED

let activePlayer: AstalMpris.Player | null = null
let lastAction: "playpause" | "next" | "prev" | null = null

function isRelevant(p: AstalMpris.Player) {
    return p.busName != null && !p.busName.includes("playerctld")
}

function pickBest(): AstalMpris.Player | null {
    const list = mpris.get_players().filter(isRelevant)
    return list.find(p => p.playbackStatus === PLAYING)
        ?? list.find(p => p.playbackStatus === PAUSED)
        ?? null
}

function playStateIcon(p: AstalMpris.Player): string {
    return p.playbackStatus === PLAYING ? PLAY_ICON : PAUSE_ICON
}

function iconForAction(action: string, p: AstalMpris.Player): string {
    if (action === "next") return NEXT_ICON
    if (action === "prev") return PREV_ICON
    return playStateIcon(p)
}

function watchPlayer(player: AstalMpris.Player) {
    player.connect("notify::playback-status", () => {
        if (player.playbackStatus === PLAYING) activePlayer = player
        if (player === activePlayer && view() === "media" && lastAction === "playpause") {
            setMedia({ ...media(), icon: playStateIcon(player) })
        }
    })
    player.connect("notify::title", () => {
        if (player === activePlayer && view() === "media") {
            setMedia({ ...media(), title: player.title || "", artist: player.artist || "" })
        }
    })
}

export function triggerMedia(action: string) {
    const player = pickBest()
    if (!player) return
    activePlayer = player

    lastAction = action === "next" || action === "prev" ? action : "playpause"

    setMedia({
        title: player.title || "",
        artist: player.artist || "",
        icon: iconForAction(action, player),
        entry: player.entry || "audio-x-generic-symbolic",
    })
    present("media")
}

export function initOsd() {
    watchDefaultSpeaker()
    wp?.connect("notify::default-speaker", () => watchDefaultSpeaker())

    for (const p of mpris.get_players()) {
        if (isRelevant(p)) watchPlayer(p)
    }
    mpris.connect("player-added", (_: AstalMpris.Mpris, player: AstalMpris.Player) => {
        if (isRelevant(player)) watchPlayer(player)
    })
    mpris.connect("player-closed", (_: AstalMpris.Mpris, player: AstalMpris.Player) => {
        if (player === activePlayer) activePlayer = pickBest()
    })
    activePlayer = pickBest()

    GLib.timeout_add(GLib.PRIORITY_DEFAULT, READY_DELAY_MS, () => {
        ready = true
        return GLib.SOURCE_REMOVE
    })
}
