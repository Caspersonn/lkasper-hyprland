import { Astal, Gtk } from "ags/gtk4"
import { createBinding } from "ags"
import { Pages } from "./widgets/pages"
import { SoundPage } from "./modules/sound-page"
import { BrightnessPage } from "./modules/brightness-page"
import AstalWp from "gi://AstalWp"

export let slidersPages: Pages | undefined

export function Sliders(): Gtk.Box {
    const wp = AstalWp.get_default()
    const speaker = wp?.audio?.defaultSpeaker

    return <Gtk.Box class="sliders" orientation={Gtk.Orientation.VERTICAL}
        hexpand spacing={10}
        onDestroy={() => { slidersPages = undefined }}>

        {/* Volume slider */}
        {speaker &&
            <Gtk.Box class="sink speaker" spacing={3}>
                <Gtk.Button onClicked={() => {
                    speaker.mute = !speaker.mute
                }} iconName={createBinding(speaker, "volumeIcon").as((icon: string) =>
                    !speaker.mute && speaker.volume > 0
                        ? icon
                        : "audio-volume-muted-symbolic"
                )} />

                <Astal.Slider drawValue={false} hexpand
                    value={createBinding(speaker, "volume")}
                    max={1.5}
                    onChangeValue={(_s: Astal.Slider, _t: Gtk.ScrollType, value: number) => {
                        speaker.set_volume(value)
                    }} />

                <Gtk.Button class="more" iconName="go-next-symbolic"
                    onClicked={() => slidersPages?.toggle(SoundPage)} />
            </Gtk.Box>
        }

        {/* Brightness slider - placeholder, wired in brightness-page module */}
        <BrightnessSlider />

        <Pages $={(self: Pages) => { slidersPages = self }} />
    </Gtk.Box> as Gtk.Box
}

function BrightnessSlider(): Gtk.Widget {
    // Brightness via brightnessctl
    // Hidden when no backlight available
    let maxBrightness = 0
    let currentBrightness = 0
    let available = false

    try {
        const { exec } = require("ags/process")
        const max = parseInt(exec("brightnessctl max"), 10)
        const cur = parseInt(exec("brightnessctl get"), 10)
        if (!isNaN(max) && max > 0) {
            maxBrightness = max
            currentBrightness = cur
            available = true
        }
    } catch { }

    if (!available) {
        return <Gtk.Box visible={false} /> as Gtk.Box
    }

    const { createState } = require("ags")
    const { exec } = require("ags/process")
    const [brightness, setBrightness] = createState(currentBrightness)

    return <Gtk.Box class="backlight" spacing={3}>
        <Gtk.Button iconName="display-brightness-symbolic"
            onClicked={() => {
                exec(`brightnessctl set ${maxBrightness}`)
                setBrightness(maxBrightness)
            }} />

        <Astal.Slider drawValue={false} hexpand
            value={brightness}
            max={maxBrightness}
            onChangeValue={(_s: Astal.Slider, _t: Gtk.ScrollType, value: number) => {
                exec(`brightnessctl set ${Math.round(value)}`)
                setBrightness(value)
            }} />

        <Gtk.Button class="more" iconName="go-next-symbolic"
            onClicked={() => slidersPages?.toggle(BrightnessPage)} />
    </Gtk.Box> as Gtk.Box
}
