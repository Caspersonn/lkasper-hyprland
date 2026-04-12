import AstalWp from "gi://AstalWp"
import { createBinding } from "ags"
import { Gtk } from "ags/gtk4"

export default function Volume() {
    const wp = AstalWp.get_default()
    const speaker = wp?.audio?.defaultSpeaker

    if (!speaker) {
        return <box class="volume module-icon separator">
            <image iconName="audio-volume-muted-symbolic" />
        </box>
    }

    return <box
        class={createBinding(speaker, "mute").as(m =>
            m
                ? "volume module-icon separator muted"
                : "volume module-icon separator"
        )}
    >
        <Gtk.EventControllerScroll
            onScroll={(_self, _dx, dy) => {
                const step = 0.05
                speaker.volume = Math.max(0, Math.min(1, speaker.volume - dy * step))
            }}
        />
        <image iconName={createBinding(speaker, "volumeIcon")} />
    </box>
}
