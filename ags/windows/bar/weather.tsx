import { createPoll } from "ags/time"
import { createComputed } from "ags"
import { execAsync } from "ags/process"
import { Gtk } from "ags/gtk4"
import { glyph } from "./glyphs"

type WeatherData = {
    temp: string
    feels: string
    humidity: string
    wind: string
    code: number
    city: string
    desc: string
    hourly: Array<{ time: string; temp: string; code: number }>
}

function codeToGlyph(code: number): string {
    if (code === 113) return glyph.weatherSunny
    if (code === 116) return glyph.weatherPartlyCloudy
    if (code === 119 || code === 122) return glyph.weatherCloudy
    if (code === 143 || code === 248 || code === 260) return glyph.weatherFog
    if (code === 200 || (code >= 386 && code <= 395)) return glyph.weatherLightning
    if ((code >= 179 && code <= 230) || (code >= 323 && code <= 377)) return glyph.weatherSnowy
    if (code >= 299 && code <= 314) return glyph.weatherPouring
    if (code >= 263 && code <= 359) return glyph.weatherRainy
    return glyph.weatherPartlyCloudy
}

function fmtHour(time: string): string {
    const h = Math.floor(Number(time) / 100)
    return `${h.toString().padStart(2, "0")}:00`
}

function parse(raw: string): WeatherData | null {
    try {
        const j = JSON.parse(raw)
        const cur = j.current_condition[0]
        const area = j.nearest_area[0]
        const hours = j.weather[0].hourly as Array<any>
        const picks = [2, 3, 4, 5, 6].map((i) => hours[i] ?? hours[hours.length - 1])
        return {
            temp: cur.temp_C,
            feels: cur.FeelsLikeC,
            humidity: cur.humidity,
            wind: cur.windspeedKmph,
            code: Number(cur.weatherCode),
            city: area.areaName[0].value,
            desc: cur.weatherDesc[0].value,
            hourly: picks.map((h) => ({
                time: fmtHour(h.time),
                temp: h.tempC,
                code: Number(h.weatherCode),
            })),
        }
    } catch {
        return null
    }
}

const raw = createPoll("", 15 * 60 * 1000, async (prev: string) => {
    try {
        const out = await execAsync(["curl", "-s", "https://wttr.in/?format=j1"])
        return out && out.length > 0 ? out : prev
    } catch {
        return prev
    }
})

const data = createComputed([raw], (r) => parse(r))

function WeatherPopover(): Gtk.Popover {
    const city = data((d) => d?.city ?? "—")
    const desc = data((d) => d?.desc ?? "")
    const temp = data((d) => (d ? `${d.temp}°` : "—"))
    const icon = data((d) => (d ? codeToGlyph(d.code) : glyph.weatherPartlyCloudy))
    const feels = data((d) => (d ? `${d.feels}°` : "—"))
    const humidity = data((d) => (d ? `${d.humidity}%` : "—"))
    const wind = data((d) => (d ? `${d.wind} km/h` : "—"))

    const forecast = (
        <box class="wx-forecast" homogeneous>
            {[0, 1, 2, 3, 4].map((i) => (
                <box class="wx-slot" valign={Gtk.Align.CENTER}>
                    <box orientation={Gtk.Orientation.VERTICAL} halign={Gtk.Align.CENTER}>
                        <label class="wx-slot-hour" label={data((d) => d?.hourly[i]?.time ?? "")} />
                        <label class="wx-slot-icon" label={data((d) => (d?.hourly[i] ? codeToGlyph(d.hourly[i].code) : ""))} />
                        <label class="wx-slot-temp" label={data((d) => (d?.hourly[i] ? `${d.hourly[i].temp}°` : ""))} />
                    </box>
                </box>
            ))}
        </box>
    )

    const content = (
        <box class="weather-popover" orientation={Gtk.Orientation.VERTICAL}>
            <box class="wx-header">
                <box orientation={Gtk.Orientation.VERTICAL} hexpand halign={Gtk.Align.START}>
                    <label class="wx-city" halign={Gtk.Align.START} label={city} />
                    <label class="wx-cond" halign={Gtk.Align.START} label={desc} />
                </box>
                <box valign={Gtk.Align.CENTER}>
                    <label class="wx-big-icon" label={icon} />
                    <label class="wx-big-temp" label={temp} />
                </box>
            </box>
            <box class="wx-tiles" homogeneous>
                <box class="wx-tile" orientation={Gtk.Orientation.VERTICAL}>
                    <label class="wx-tile-label" halign={Gtk.Align.START} label="FEELS" />
                    <label class="wx-tile-value" halign={Gtk.Align.START} label={feels} />
                </box>
                <box class="wx-tile" orientation={Gtk.Orientation.VERTICAL}>
                    <label class="wx-tile-label" halign={Gtk.Align.START} label="HUMIDITY" />
                    <label class="wx-tile-value" halign={Gtk.Align.START} label={humidity} />
                </box>
                <box class="wx-tile" orientation={Gtk.Orientation.VERTICAL}>
                    <label class="wx-tile-label" halign={Gtk.Align.START} label="WIND" />
                    <label class="wx-tile-value" halign={Gtk.Align.START} label={wind} />
                </box>
            </box>
            <label class="wx-next-label" halign={Gtk.Align.START} label="NEXT HOURS" />
            {forecast}
        </box>
    ) as Gtk.Widget

    const pop = new Gtk.Popover()
    pop.set_has_arrow(false)
    pop.add_css_class("popover-wrap")
    pop.set_child(content)
    return pop
}

export default function Weather() {
    const pop = WeatherPopover()
    const icon = data((d) => (d ? codeToGlyph(d.code) : glyph.weatherPartlyCloudy))
    const temp = data((d) => (d ? `${d.temp}°` : "—"))
    const city = data((d) => d?.city ?? "")

    return (
        <button
            class="weather island-sub"
            onClicked={() => pop.popup()}
            $={(self) => pop.set_parent(self)}
        >
            <box>
                <label class="weather-icon" label={icon} />
                <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER}>
                    <label class="weather-temp" halign={Gtk.Align.START} label={temp} />
                    <label class="weather-city" halign={Gtk.Align.START} label={city} />
                </box>
            </box>
        </button>
    )
}
