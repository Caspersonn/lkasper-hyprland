import { createBinding, For } from "ags";
import AstalTray from "gi://AstalTray";


export default function Tray() {
    const tray = AstalTray.get_default();

    const items = createBinding(tray, "items");

    return <box class="tray">
        <For each={items}>
            {(item: any) => (
                <button
                    class="tray-item tray-separator"
                    tooltipMarkup={createBinding(item, "tooltipMarkup")}
                    onClicked={() => { item.aboutToShow(); item.activate(0, 0); }}
                >
                    <image gicon={createBinding(item, "gicon")} pixelSize={16} />
                </button>
            )}
        </For>
    </box>;
}

