import AstalBattery from "gi://AstalBattery"
import { createBinding } from "ags"

export default function Battery() {
    const bat = AstalBattery.get_default()

    return <box
        visible={createBinding(bat, "isPresent")}
        class={createBinding(bat, "percentage").as((pct: number) => {
            const charging = bat.charging
            const base = "battery separator"
            if (charging) return `${base} charging`
            if (pct <= 0.1) return `${base} critical`
            if (pct <= 0.2) return `${base} warning`
            return base
        })}
        tooltipText={createBinding(bat, "percentage").as((pct: number) =>
            `${Math.round(pct * 100)}%${bat.charging ? " (charging)" : ""}`
        )}
    >
        <image class="module-icon" iconName={createBinding(bat, "batteryIconName")} />
    </box>
}
