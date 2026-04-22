import App from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import { property, register } from "ags/gobject"
import GObject from "gi://GObject"
import QuickActions from "./quick-actions"
import { Tiles } from "./tiles"
import { Sliders } from "./sliders"

// Shared state for panel open/close (bindable from right-pill for highlight)
@register({ GTypeName: "LkhQsState" })
class QsStateClass extends GObject.Object {
    @property(Boolean) isOpen: boolean = false
}

export const qsState = new QsStateClass()

let _window: Astal.Window | null = null

export function toggleQuickSettings() {
    if (!_window) return
    _window.visible ? closeQuickSettings() : openQuickSettings()
}

export function openQuickSettings() {
    if (!_window || _window.visible) return
    _window.visible = true
    qsState.isOpen = true
}

export function closeQuickSettings() {
    if (!_window || !_window.visible) return
    _window.visible = false
    qsState.isOpen = false
}

export default function QuickSettings() {
    let clickedInside = false

    const win = <window
        name="quick-settings"
        namespace="quick-settings"
        application={App}
        class="quick-settings"
        anchor={
            Astal.WindowAnchor.TOP |
            Astal.WindowAnchor.LEFT |
            Astal.WindowAnchor.BOTTOM |
            Astal.WindowAnchor.RIGHT
        }
        keymode={Astal.Keymode.EXCLUSIVE}
        visible={false}
    >
        {/* Escape key handler */}
        <Gtk.EventControllerKey onKeyReleased={(_self: Gtk.EventControllerKey, keyval: number) => {
            if (keyval === 65307) closeQuickSettings() // Escape
        }} />

        {/* Outside click handler */}
        <Gtk.GestureClick onReleased={() => {
            if (clickedInside) {
                clickedInside = false
                return
            }
            closeQuickSettings()
        }} />

        {/* Inner panel positioned top-right */}
        <Gtk.Box class="quick-settings-panel"
            orientation={Gtk.Orientation.VERTICAL}
            halign={Gtk.Align.END}
            valign={Gtk.Align.START}
            spacing={12}
            widthRequest={395}>

            {/* Inside click marker */}
            <Gtk.GestureClick onPressed={() => { clickedInside = true }} />

            <Gtk.Box class="control-center-container"
                orientation={Gtk.Orientation.VERTICAL}
                spacing={12}
                vexpand={false}>

                <QuickActions />
                <Tiles />
                <Sliders />
            </Gtk.Box>
        </Gtk.Box>
    </window>

    _window = win as Astal.Window
    return win
}
