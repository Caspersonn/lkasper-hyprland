import Clock from "./clock"
import Media from "./media"

export default function CenterPill() {
    return <box class="pill center-pill">
        <Clock />
        <Media />
    </box>
}
