import { Astal, Gtk } from "ags/gtk4"
import { createBinding, createRoot, For } from "ags"
import { Page, PageButton } from "../widgets/page"
import AstalWp from "gi://AstalWp"

export const SoundPage = createRoot((_dispose) => new Page({
    id: "sound",
    title: "Sound",
    description: "Output devices & apps",
    content: () => {
        const wp = AstalWp.get_default()
        const audio = wp?.audio

        return [
            // Output device selector
            <Gtk.Label class="sub-header" label="Devices" xalign={0} />,
            <Gtk.Box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                {audio && <For each={createBinding(audio, "speakers")}>
                    {(sink: AstalWp.Endpoint) =>
                        <PageButton
                            class={createBinding(sink, "isDefault").as((d: boolean) =>
                                d ? "selected" : ""
                            )}
                            icon={createBinding(sink, "icon").as((i: string) =>
                                i ?? "audio-card-symbolic"
                            )}
                            title={createBinding(sink, "description").as((d: string) =>
                                d ?? "Speaker"
                            )}
                            actionClicked={() => {
                                if (!sink.isDefault) sink.set_is_default(true)
                            }}
                            endWidget={
                                <Gtk.Image iconName="object-select-symbolic"
                                    visible={createBinding(sink, "isDefault")} />
                            }
                        />
                    }
                </For>}
            </Gtk.Box>,

            // Per-app audio streams
            <Gtk.Box orientation={Gtk.Orientation.VERTICAL} spacing={8}
                visible={audio
                    ? createBinding(audio, "streams").as((s: AstalWp.Stream[]) => s.length > 0)
                    : false
                }>
                <Gtk.Label class="sub-header" label="Apps" xalign={0} />
                {audio && <For each={createBinding(audio, "streams")}>
                    {(stream: AstalWp.Stream) =>
                        <Gtk.Box hexpand>
                            <Gtk.Image iconName="application-x-executable-symbolic" />
                            <Gtk.Box orientation={Gtk.Orientation.VERTICAL} hexpand>
                                <Gtk.Label label={createBinding(stream, "description").as(
                                    (d: string) => d ?? "Audio stream"
                                )} class="name" xalign={0} />
                                <Astal.Slider drawValue={false}
                                    value={createBinding(stream, "volume")}
                                    min={0} max={1.5} hexpand
                                    onChangeValue={(_s: Astal.Slider, _t: Gtk.ScrollType, value: number) => {
                                        stream.set_volume(value)
                                    }} />
                            </Gtk.Box>
                        </Gtk.Box>
                    }
                </For>}
            </Gtk.Box>,
        ]
    },
}))
