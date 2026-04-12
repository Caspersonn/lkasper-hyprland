import { readFile } from "ags/file"
import { createPoll } from "ags/time"

let prevIdle = 0
let prevTotal = 0

const cpu = createPoll(0, 3000, () => {
    const content = readFile("/proc/stat")
    const line = content.split("\n")[0]
    const values = line.split(/\s+/).slice(1).map(Number)
    const idle = values[3] + values[4]
    const total = values.reduce((a, b) => a + b, 0)
    const dIdle = idle - prevIdle
    const dTotal = total - prevTotal
    prevIdle = idle
    prevTotal = total
    if (dTotal === 0) return 0
    return Math.round((1 - dIdle / dTotal) * 100)
})

export default function Cpu() {
    return <box class="cpu module-text separator">
        <label label={cpu.as(v => `${v}%`)} />
    </box>
}
