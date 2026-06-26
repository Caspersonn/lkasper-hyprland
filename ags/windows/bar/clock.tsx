import { Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import { glyph } from "./glyphs"
import Calendar from "./calendar"

const DAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
const MONTHS = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
]

const pad = (n: number) => String(n).padStart(2, "0")

const timeLabel = createPoll("", 1000, () => {
    const now = new Date()
    return `${pad(now.getHours())}:${pad(now.getMinutes())}`
})

const dateLabel = createPoll("", 1000 * 30, () => {
    const now = new Date()
    return `${DAYS[now.getDay()]} ${pad(now.getDate())} ${MONTHS[now.getMonth()]}`
})

export default function Clock() {
    const popover = Calendar()
    return (
        <button
            class="clock island-btn"
            $={(self: Gtk.Button) => popover.set_parent(self)}
            onClicked={() => popover.popup()}
        >
            <box class="clock-inner">
                <label class="clock-cal-icon" label={glyph.calendar} />
                <label class="clock-time" label={timeLabel} />
                <box class="clock-divider" valign={Gtk.Align.CENTER} />
                <label class="clock-date" label={dateLabel} />
            </box>
        </button>
    )
}
