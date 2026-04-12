import AstalTray from "gi://AstalTray"
import { createBinding, For } from "ags"

export default function Tray() {
    const tray = AstalTray.get_default()

    const items = createBinding(tray, "items")

    return <box class="tray">
        <For each={items}>
            {item => (
                <button
                    class="tray-item"
                    tooltipMarkup={createBinding(item, "tooltipMarkup")}
                    onClicked={() => item.activate(0, 0)}
                >
                    <image gicon={createBinding(item, "gicon")} pixelSize={16} />
                </button>
            )}
        </For>
    </box>
}
