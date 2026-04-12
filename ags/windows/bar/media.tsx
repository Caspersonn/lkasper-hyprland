import AstalMpris from "gi://AstalMpris"
import { createBinding } from "ags"

export default function Media() {
    const mpris = AstalMpris.get_default()
    const status = AstalMpris.PlaybackStatus

    const players = createBinding(mpris, "players")

    const label = players.as(list => {
        if (list.length === 0) return ""
        const player = list.find(p => p.playbackStatus === AstalMpris.PlaybackStatus.PLAYING)
          ?? list.find(p => p.playbackStatus === AstalMpris.PlaybackStatus.PAUSED)
          ?? list[0]
        const title = player.title || ""
        return player.artist ? `${player.artist} - ${title}` : title
    })
    const visible = players.as(list => list.length > 0)

    return <box>
        <label class="media-label separator" label={label} visible={visible} />
    </box>
}
