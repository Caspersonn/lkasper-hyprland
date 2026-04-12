import AstalBattery from "gi://AstalBattery"
import { createBinding } from "ags"

export default function Battery() {
    const bat = AstalBattery.get_default()
    print(bat.percentage * 100)

    return <box class={createBinding(bat, "charging").as(c => {
        const base = "battery separator"
        if (c) return `${base} charging`
        return base
    })}>
        <image class="module-icon" iconName={createBinding(bat, "iconName")} />
        <label label={createBinding(bat, "percentage").as(p => `${p * 100}%`)} />
    </box>
}
