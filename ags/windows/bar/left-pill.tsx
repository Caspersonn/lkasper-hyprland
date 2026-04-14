import Workspaces from "./workspaces"
import Clients from "./clients"

export default function LeftPill() {
    return <box class="pill left-pill">
        <Workspaces />
        <Clients />
    </box>
}
