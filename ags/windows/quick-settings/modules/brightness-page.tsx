import { Astal, Gtk } from "ags/gtk4"
import { createRoot } from "ags"
import { Page } from "../widgets/page"
import { exec } from "ags/process"

export const BrightnessPage = createRoot((_dispose) => new Page({
    id: "brightness",
    title: "Brightness",
    description: "Display backlight",
    content: () => {
        let maxBrightness = 0
        let currentBrightness = 0

        try {
            maxBrightness = parseInt(exec("brightnessctl max"), 10)
            currentBrightness = parseInt(exec("brightnessctl get"), 10)
        } catch {
            return [
                <Gtk.Label label="No backlight devices found" xalign={0} />,
            ]
        }

        if (isNaN(maxBrightness) || maxBrightness <= 0) {
            return [
                <Gtk.Label label="No backlight devices found" xalign={0} />,
            ]
        }

        return [
            <Gtk.Label class="sub-header" label="Backlight" xalign={0} />,
            <Astal.Slider
                value={currentBrightness}
                min={0}
                max={maxBrightness}
                drawValue={false}
                onChangeValue={(_s: Astal.Slider, _t: Gtk.ScrollType, value: number) => {
                    exec(`brightnessctl set ${Math.round(value)}`)
                }}
            />,
        ]
    },
}))
