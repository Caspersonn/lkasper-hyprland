import { Tile } from "../widgets/tile"
import { createState } from "ags"

// Local DND state — will be connected to astal-notifd in Phase 5
// when swaync is replaced with our own notification daemon
const [isDnd, setIsDnd] = createState(false)

export function DndTile(): Tile {
    return <Tile
        title="Do Not Disturb"
        icon="minus-circle-filled-symbolic"
        toggleOnClick
        state={isDnd}
        description={isDnd.as((dnd: boolean) =>
            dnd ? "Enabled" : "Disabled"
        )}
        onEnabled={() => setIsDnd(true)}
        onDisabled={() => setIsDnd(false)}
    /> as Tile
}
