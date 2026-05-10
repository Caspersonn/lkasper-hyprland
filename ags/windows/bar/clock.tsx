import { createPoll } from "ags/time"

const DAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

const time = createPoll("", 1000, () => {
    const now = new Date()
    const day = DAYS[now.getDay()]
    const hours = String(now.getHours()).padStart(2, "0")
    const minutes = String(now.getMinutes()).padStart(2, "0")
    return `${day} ${hours}:${minutes}`
})

export default function Clock() {
    return <label class="clock" label={time} />
}
