import AstalNetwork from "gi://AstalNetwork"
import AstalWp from "gi://AstalWp"
import AstalBluetooth from "gi://AstalBluetooth"
import AstalNotifd from "gi://AstalNotifd"
import AstalBattery from "gi://AstalBattery"
import { createBinding, createComputed, createState, With } from "ags"
import { createPoll } from "ags/time"
import { Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { glyph } from "./glyphs"

const PROFILES = [
    { id: "power-saver", label: "Saver", icon: glyph.leaf },
    { id: "balanced", label: "Balanced", icon: glyph.scaleBalance },
    { id: "performance", label: "Turbo", icon: glyph.rocketLaunch },
]

function batInfo(pct: number, charging: boolean): { icon: string; cls: string } {
    if (charging) return { icon: glyph.batteryCharging, cls: "bat-good" }
    if (pct > 0.8) return { icon: glyph.battery, cls: "bat-good" }
    if (pct > 0.6) return { icon: glyph.battery80, cls: "bat-ok" }
    if (pct > 0.4) return { icon: glyph.battery60, cls: "bat-mid" }
    if (pct > 0.2) return { icon: glyph.battery40, cls: "bat-low" }
    return { icon: glyph.battery20, cls: "bat-crit" }
}

function Tile(props: {
    active: ReturnType<typeof createComputed<boolean>> | any
    icon: any
    name: string
    sub?: any
    onClicked: () => void
}) {
    const cssClasses = props.active.as((a: boolean) => ["cc-tile", a ? "on" : "off"])
    return (
        <button cssClasses={cssClasses} onClicked={props.onClicked}>
            <box>
                <label class="cc-tile-icon" label={props.icon} />
                <box orientation={Gtk.Orientation.VERTICAL} hexpand halign={Gtk.Align.START}>
                    <label class="cc-tile-name" halign={Gtk.Align.START} label={props.name} />
                    {props.sub ? (
                        <label class="cc-tile-sub" halign={Gtk.Align.START} label={props.sub} />
                    ) : (
                        <box />
                    )}
                </box>
            </box>
        </button>
    )
}

function Header() {
    const bat = AstalBattery.get_default()
    const icon = createComputed(
        [createBinding(bat, "percentage"), createBinding(bat, "charging")],
        (p: number, c: boolean) => batInfo(p, c).icon,
    )
    const cls = createComputed(
        [createBinding(bat, "percentage"), createBinding(bat, "charging")],
        (p: number, c: boolean) => `cc-bat ${batInfo(p, c).cls}`,
    )
    const label = createBinding(bat, "percentage").as((p: number) => `${Math.round(p * 100)}%`)
    return (
        <box class="cc-header">
            <label class="cc-title" hexpand halign={Gtk.Align.START} label="Control Center" />
            <box class={cls} visible={createBinding(bat, "isPresent")}>
                <label class="cc-bat-icon" label={icon} />
                <label class="cc-bat-label" label={label} />
            </box>
        </box>
    )
}

function Toggles() {
    const network = AstalNetwork.get_default()
    const bt = AstalBluetooth.get_default()
    const notifd = AstalNotifd.get_default()
    const [night, setNight] = createState(false)

    const dndActive = createBinding(notifd, "dontDisturb")
    const dndSub = dndActive.as((on: boolean) => (on ? "Muted" : "Allowed"))
    const btActive = createBinding(bt, "isPowered")
    const btSub = createComputed(
        [createBinding(bt, "isPowered"), createBinding(bt, "devices")],
        (on: boolean, devices: any[]) => {
            if (!on) return "Off"
            const connected = devices.filter((d) => d.connected)
            return connected.length ? connected[0].name : "On"
        },
    )

    return (
        <box class="cc-toggles" homogeneous>
            <box orientation={Gtk.Orientation.VERTICAL} hexpand>
                <With value={createBinding(network, "wifi")}>
                    {(wifi) =>
                        wifi ? (
                            <Tile
                                active={createBinding(wifi, "enabled")}
                                icon={createBinding(wifi, "enabled").as((e: boolean) =>
                                    e ? glyph.wifi : glyph.wifiOff,
                                )}
                                name="Wi-Fi"
                                sub={createComputed(
                                    [createBinding(wifi, "enabled"), createBinding(wifi, "ssid")],
                                    (e: boolean, ssid: string) => (e ? ssid || "On" : "Off"),
                                )}
                                onClicked={() => {
                                    wifi.enabled = !wifi.enabled
                                }}
                            />
                        ) : (
                            <Tile
                                active={createState(false)[0]}
                                icon={glyph.wifiOff}
                                name="Wi-Fi"
                                sub="Off"
                                onClicked={() => {}}
                            />
                        )
                    }
                </With>
                <Tile
                    active={dndActive}
                    icon={glyph.bellOff}
                    name="Do Not Disturb"
                    sub={dndSub}
                    onClicked={() => {
                        notifd.dontDisturb = !notifd.dontDisturb
                    }}
                />
            </box>
            <box orientation={Gtk.Orientation.VERTICAL} hexpand>
                <Tile
                    active={btActive}
                    icon={btActive.as((p: boolean) => (p ? glyph.bluetooth : glyph.bluetoothOff))}
                    name="Bluetooth"
                    sub={btSub}
                    onClicked={() => {
                        const adapter = bt.adapter
                        if (adapter) adapter.powered = !adapter.powered
                    }}
                />
                <Tile
                    active={night}
                    icon={glyph.weatherNight}
                    name="Night Light"
                    sub={night.as((on: boolean) => (on ? "3500K" : "Off"))}
                    onClicked={() => {
                        const next = !night.get()
                        setNight(next)
                        execAsync(next ? ["hyprsunset", "-t", "3500"] : ["hyprsunset", "-i"]).catch(
                            () => {},
                        )
                    }}
                />
            </box>
        </box>
    )
}

function Sliders() {
    const wp = AstalWp.get_default()
    const speaker = wp?.audio?.defaultSpeaker
    const brightness = createPoll(0, 5000, async () => {
        try {
            const g = parseInt(await execAsync(["brightnessctl", "get"]))
            const m = parseInt(await execAsync(["brightnessctl", "max"]))
            return m ? g / m : 0
        } catch {
            return 0
        }
    })

    return (
        <box orientation={Gtk.Orientation.VERTICAL} class="cc-sliders">
            {speaker ? (
                <box class="cc-slider-row">
                    <button
                        class="cc-slider-icon cc-vol-icon"
                        onClicked={() => {
                            speaker.mute = !speaker.mute
                        }}
                    >
                        <label
                            label={createComputed(
                                [createBinding(speaker, "mute"), createBinding(speaker, "volume")],
                                (m: boolean, v: number) =>
                                    m
                                        ? glyph.volumeMute
                                        : v > 0.55
                                          ? glyph.volumeHigh
                                          : v > 0
                                            ? glyph.volumeMedium
                                            : glyph.volumeLow,
                            )}
                        />
                    </button>
                    <slider
                        class="cc-vol"
                        hexpand
                        value={createBinding(speaker, "volume")}
                        onChangeValue={(self: Gtk.Scale) => {
                            speaker.volume = self.value
                        }}
                    />
                    <label
                        class="cc-slider-val"
                        label={createBinding(speaker, "volume").as(
                            (v: number) => `${Math.round(v * 100)}`,
                        )}
                    />
                </box>
            ) : (
                <box />
            )}
            <box class="cc-slider-row">
                <label class="cc-slider-icon cc-bright-icon" label={glyph.brightness} />
                <slider
                    class="cc-bright"
                    hexpand
                    value={brightness}
                    onChangeValue={(self: Gtk.Scale) => {
                        execAsync([
                            "brightnessctl",
                            "set",
                            `${Math.round(self.value * 100)}%`,
                        ]).catch(() => {})
                    }}
                />
                <label
                    class="cc-slider-val"
                    label={brightness.as((v: number) => `${Math.round(v * 100)}`)}
                />
            </box>
        </box>
    )
}

function PowerProfile() {
    const profile = createPoll("balanced", 5000, async () => {
        try {
            return (await execAsync(["powerprofilesctl", "get"])).trim()
        } catch {
            return "balanced"
        }
    })

    return (
        <box orientation={Gtk.Orientation.VERTICAL} class="cc-profile">
            <label class="cc-section-label" halign={Gtk.Align.START} label="POWER PROFILE" />
            <box class="cc-segments" homogeneous>
                {PROFILES.map((p) => (
                    <button
                        cssClasses={profile.as((cur: string) => [
                            "cc-segment",
                            cur === p.id ? "active" : "",
                        ])}
                        onClicked={() => {
                            execAsync(["powerprofilesctl", "set", p.id]).catch(() => {})
                        }}
                    >
                        <box orientation={Gtk.Orientation.VERTICAL}>
                            <label class="cc-segment-icon" label={p.icon} />
                            <label class="cc-segment-label" label={p.label} />
                        </box>
                    </button>
                ))}
            </box>
        </box>
    )
}

export default function ControlCenter(): Gtk.Popover {
    const content = (
        <box orientation={Gtk.Orientation.VERTICAL} class="control-center">
            <Header />
            <Toggles />
            <Sliders />
            <PowerProfile />
        </box>
    ) as Gtk.Widget

    const pop = new Gtk.Popover()
    pop.set_has_arrow(false)
    pop.add_css_class("popover-wrap")
    pop.set_child(content)
    return pop
}
