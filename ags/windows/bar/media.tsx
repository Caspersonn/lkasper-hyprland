import AstalMpris from "gi://AstalMpris"
import { createState, createComputed } from "ags"

export default function Media() {
    const mpris = AstalMpris.get_default()
    const PLAYING = AstalMpris.PlaybackStatus.PLAYING
    const PAUSED = AstalMpris.PlaybackStatus.PAUSED

    const [title, setTitle] = createState("")
    const [artist, setArtist] = createState("")
    const [entry, setEntry] = createState("")
    const [visible, setVisible] = createState(false)

    let activePlayer: AstalMpris.Player | null = null

    function isRelevant(p: AstalMpris.Player) {
        return p.busName != null && !p.busName.includes("playerctld")
    }

    function pickBest(): AstalMpris.Player | null {
        const list = mpris.get_players().filter(isRelevant)
        return list.find(p => p.playbackStatus === PLAYING)
            ?? list.find(p => p.playbackStatus === PAUSED)
            ?? null
    }

    function activate(player: AstalMpris.Player | null) {
        activePlayer = player
        setTitle(player?.title || "")
        setArtist(player?.artist || "")
        setEntry(player?.entry || "audio-x-generic-symbolic")
        setVisible(player != null && (player.title !== "" || player.artist !== ""))
    }

    function watchPlayer(player: AstalMpris.Player) {
        player.connect("notify::playback-status", () => {
            if (player.playbackStatus === PLAYING) {
                activate(player)
            } else if (player === activePlayer) {
                const better = pickBest()
                if (better) activate(better)
            }
        })
        player.connect("notify::title", () => {
            if (player === activePlayer) {
                setTitle(player.title || "")
                setVisible(player.title !== "" || player.artist !== "")
            }
        })
        player.connect("notify::artist", () => {
            if (player === activePlayer) setArtist(player.artist || "")
        })
    }

    for (const p of mpris.get_players()) {
        if (isRelevant(p)) watchPlayer(p)
    }

    mpris.connect("player-added", (_: any, player: AstalMpris.Player) => {
        if (isRelevant(player)) {
            watchPlayer(player)
            if (player.playbackStatus === PLAYING) activate(player)
        }
    })

    mpris.connect("player-closed", (_: any, player: AstalMpris.Player) => {
        if (player === activePlayer) activate(pickBest())
    })

    activate(pickBest())

    const label = createComputed(() => {
        const a = artist()
        const t = title()
        return a ? `${a} - ${t}` : t
    })

    const iconName = createComputed(() => entry() || "audio-x-generic-symbolic")

    return <box visible={visible} class="media-entry separator">
        <image class="media-icon" iconName={iconName} />
        <label class="media-label" label={label} />
    </box>
}
