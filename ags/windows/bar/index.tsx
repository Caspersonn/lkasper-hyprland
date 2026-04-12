import App from "ags/gtk4/app"
import { Astal } from "ags/gtk4"
import LeftPill from "./left-pill"
import CenterPill from "./center-pill"
import RightPill from "./right-pill"

export default function Bar() {
    return <window
        name="bar"
        namespace="bar"
        application={App}
        class="bar"
        anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        marginTop={8}
        marginLeft={8}
        marginRight={8}
        visible
    >
        <centerbox>
            <box $type="start">
                <LeftPill />
            </box>
            <box $type="center">
                <CenterPill />
            </box>
            <box $type="end">
                <RightPill />
            </box>
        </centerbox>
    </window>
}
