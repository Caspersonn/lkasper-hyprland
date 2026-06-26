import { Gtk } from "ags/gtk4"
import { createState, createComputed, For } from "ags"
import { createPoll } from "ags/time"
import { glyph } from "./glyphs"

const MONTHS = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
]

const WEEKDAYS = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

const pad = (n: number) => String(n).padStart(2, "0")

const bigTime = createPoll("", 1000, () => {
    const now = new Date()
    return `${pad(now.getHours())}:${pad(now.getMinutes())}`
})

const seconds = createPoll("", 1000, () => `:${pad(new Date().getSeconds())}`)

type Cell = { key: string; label: string; cls: string[] }

export default function Calendar(): Gtk.Popover {
    const [offset, setOffset] = createState(0)

    const monthLabel = createComputed([offset], (o) => {
        const d = new Date()
        d.setDate(1)
        d.setMonth(d.getMonth() + o)
        return `${MONTHS[d.getMonth()]} ${d.getFullYear()}`
    })

    const weeks = createComputed([offset], (o) => {
        const now = new Date()
        const base = new Date(now.getFullYear(), now.getMonth() + o, 1)
        const year = base.getFullYear()
        const month = base.getMonth()
        const firstDow = base.getDay()
        const daysInMonth = new Date(year, month + 1, 0).getDate()
        const prevDays = new Date(year, month, 0).getDate()
        const isCurMonth = o === 0
        const today = now.getDate()

        const cells: Cell[] = []
        for (let i = 0; i < firstDow; i++) {
            const d = prevDays - firstDow + 1 + i
            cells.push({ key: `lead-${d}`, label: `${d}`, cls: ["cal-cell", "other-month"] })
        }
        for (let d = 1; d <= daysInMonth; d++) {
            const cls = ["cal-cell"]
            if (isCurMonth && d === today) cls.push("today")
            cells.push({ key: `day-${d}`, label: `${d}`, cls })
        }
        let trail = 1
        while (cells.length < 42) {
            cells.push({ key: `trail-${trail}`, label: `${trail}`, cls: ["cal-cell", "other-month"] })
            trail++
        }

        const rows: { key: string; cells: Cell[] }[] = []
        for (let r = 0; r < 6; r++) {
            rows.push({ key: `row-${r}`, cells: cells.slice(r * 7, r * 7 + 7) })
        }
        return rows
    })

    const content = (
        <box class="calendar-popover" orientation={Gtk.Orientation.VERTICAL} spacing={4}>
            <box class="cal-header">
                <box class="cal-time-wrap" hexpand valign={Gtk.Align.END}>
                    <label class="cal-time" label={bigTime} />
                    <label class="cal-seconds" label={seconds} valign={Gtk.Align.END} />
                </box>
                <box class="cal-nav" spacing={4} halign={Gtk.Align.END} valign={Gtk.Align.CENTER}>
                    <button class="cal-chevron" onClicked={() => setOffset(offset.get() - 1)}>
                        <label label={glyph.chevronLeft} />
                    </button>
                    <label class="cal-month" label={monthLabel} halign={Gtk.Align.CENTER} />
                    <button class="cal-chevron" onClicked={() => setOffset(offset.get() + 1)}>
                        <label label={glyph.chevronRight} />
                    </button>
                </box>
            </box>
            <box class="cal-weekdays" homogeneous>
                {WEEKDAYS.map((w) => (
                    <label class="cal-weekday" label={w} />
                ))}
            </box>
            <box class="cal-grid" orientation={Gtk.Orientation.VERTICAL} spacing={3}>
                <For each={weeks}>
                    {(week: { key: string; cells: Cell[] }) => (
                        <box class="cal-week" homogeneous spacing={3}>
                            {week.cells.map((cell) => (
                                <label cssClasses={cell.cls} label={cell.label} />
                            ))}
                        </box>
                    )}
                </For>
            </box>
        </box>
    ) as Gtk.Widget

    const popover = new Gtk.Popover()
    popover.set_has_arrow(false)
    popover.add_css_class("popover-wrap")
    popover.set_child(content)
    return popover
}
