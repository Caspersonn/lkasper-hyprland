import { Gtk } from "ags/gtk4"
import { createRoot } from "ags"
import { Pages } from "./widgets/pages"
import { NetworkTile } from "./modules/network-tile"
import { BluetoothTile } from "./modules/bluetooth-tile"
import { DndTile } from "./modules/dnd-tile"
import { NightLightTile } from "./modules/night-light-tile"

export let tilesPages: Pages | undefined

const tileList: Array<() => Gtk.Widget> = [
    NetworkTile,
    BluetoothTile,
    DndTile,
    NightLightTile,
]

export function Tiles(): Gtk.Widget {
    return createRoot((dispose) => {
        return <Gtk.Box class="tiles-container" orientation={Gtk.Orientation.VERTICAL}
            onDestroy={() => { tilesPages = undefined; dispose() }}>

            <Gtk.FlowBox orientation={Gtk.Orientation.HORIZONTAL}
                rowSpacing={6} columnSpacing={6}
                minChildrenPerLine={2} maxChildrenPerLine={2}
                activateOnSingleClick hexpand homogeneous>
                {tileList.map(t => t())}
            </Gtk.FlowBox>

            <Pages $={(self: Pages) => { tilesPages = self }} />
        </Gtk.Box> as Gtk.Box
    })
}
