import { Astal, Gtk } from "ags/gtk4"
import { createRoot } from "ags"
import { Page } from "../widgets/page"
import { getTemperature, setNightLightTemperature } from "./night-light-tile"

export const NightLightPage = createRoot((dispose) => new Page({
    id: "night-light",
    title: "Night Light",
    description: "Adjust color temperature",
    actionClosed: () => dispose(),
    content: () => [
        <Gtk.Label class="sub-header" label="Temperature" xalign={0} />,
        <Astal.Slider
            class="temperature"
            value={getTemperature()}
            min={1000}
            max={6500}
            drawValue={false}
            onChangeValue={(_s: Astal.Slider, _t: Gtk.ScrollType, value: number) => {
                setNightLightTemperature(Math.floor(value))
            }}
        />,
    ],
}))
