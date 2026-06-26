import AstalWp from "gi://AstalWp"
import AstalBattery from "gi://AstalBattery"
import AstalNetwork from "gi://AstalNetwork"
import AstalBluetooth from "gi://AstalBluetooth"
import { createBinding, createComputed } from "ags"
import { glyph } from "./glyphs"
import ControlCenter from "./control-center"

function volGlyph(mute: boolean, vol: number): string {
    if (mute) return glyph.volumeMute
    if (vol > 0.55) return glyph.volumeHigh
    if (vol > 0) return glyph.volumeMedium
    return glyph.volumeLow
}

function batInfo(pct: number, charging: boolean): { icon: string; cls: string } {
    if (charging) return { icon: glyph.batteryCharging, cls: "bat-good" }
    if (pct > 0.8) return { icon: glyph.battery, cls: "bat-good" }
    if (pct > 0.6) return { icon: glyph.battery80, cls: "bat-ok" }
    if (pct > 0.4) return { icon: glyph.battery60, cls: "bat-mid" }
    if (pct > 0.2) return { icon: glyph.battery40, cls: "bat-low" }
    return { icon: glyph.battery20, cls: "bat-crit" }
}

export default function QuickControls() {
    const pop = ControlCenter()
    const wp = AstalWp.get_default()
    const speaker = wp?.audio?.defaultSpeaker
    const bat = AstalBattery.get_default()
    const network = AstalNetwork.get_default()
    const bt = AstalBluetooth.get_default()
    const wifi = network.wifi

    const volIcon = speaker
        ? createComputed(
              [createBinding(speaker, "mute"), createBinding(speaker, "volume")],
              (m: boolean, v: number) => volGlyph(m, v),
          )
        : null

    const wifiIcon = wifi
        ? createBinding(wifi, "enabled").as((e: boolean) => (e ? glyph.wifi : glyph.wifiOff))
        : null

    const btIcon = createBinding(bt, "isPowered").as((p: boolean) =>
        p ? glyph.bluetooth : glyph.bluetoothOff,
    )

    const batIcon = createComputed(
        [createBinding(bat, "percentage"), createBinding(bat, "charging")],
        (p: number, c: boolean) => batInfo(p, c).icon,
    )
    const batClass = createComputed(
        [createBinding(bat, "percentage"), createBinding(bat, "charging")],
        (p: number, c: boolean) => `qc-battery ${batInfo(p, c).cls}`,
    )
    const batLabel = createBinding(bat, "percentage").as((p: number) => `${Math.round(p * 100)}%`)

    return (
        <button
            class="quick-controls island-sub"
            onClicked={() => pop.popup()}
            $={(self) => pop.set_parent(self)}
        >
            <box>
                <label class="qc-icon qc-brightness" label={glyph.brightness} />
                <label class="qc-icon qc-volume" label={volIcon ?? glyph.volumeOff} />
                <label class="qc-icon qc-wifi" label={wifiIcon ?? glyph.wifiOff} />
                <label class="qc-icon qc-bt" label={btIcon} />
                <box class={batClass} visible={createBinding(bat, "isPresent")}>
                    <label class="qc-bat-icon" label={batIcon} />
                    <label class="qc-bat-label" label={batLabel} />
                </box>
            </box>
        </button>
    )
}
