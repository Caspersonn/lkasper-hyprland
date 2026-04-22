import { Gtk } from "ags/gtk4"
import { createBinding } from "ags"
import { property, register, signal } from "ags/gobject"
import Pango from "gi://Pango"

@register({ GTypeName: "LkhTile" })
export class Tile extends Gtk.Box {
    @signal(Boolean)
    toggled(_state: boolean) {}

    @signal()
    enabled() {}

    @signal()
    disabled() {}

    @signal()
    clicked() {
        if (!this.toggleOnClick) return
        this.state ? this.disable() : this.enable()
    }

    @property(String)
    icon: string = ""

    @property(String)
    title: string = ""

    @property(String)
    description: string = ""

    @property(Boolean)
    toggleOnClick: boolean = false

    @property(Boolean)
    state: boolean = false

    @property(Boolean)
    hasArrow: boolean = false

    enable(): void {
        if (this.state) return
        this.state = true
        if (!this.has_css_class("enabled")) this.add_css_class("enabled")
        this.emit("toggled", true)
        this.emit("enabled")
    }

    disable(): void {
        if (!this.state) return
        this.state = false
        this.remove_css_class("enabled")
        this.emit("toggled", false)
        this.emit("disabled")
    }

    constructor(props: Record<string, any> = {}) {
        const { icon, title, description, state, toggleOnClick, hasArrow, ...rest } = props
        super(rest)

        this.add_css_class("tile")
        this.hexpand = true

        if (icon !== undefined) this.icon = icon
        if (title !== undefined) this.title = title
        if (description !== undefined) this.description = description
        if (state !== undefined) this.state = state
        if (toggleOnClick !== undefined) this.toggleOnClick = toggleOnClick
        if (hasArrow !== undefined) this.hasArrow = hasArrow
        if (this.state) this.add_css_class("enabled")

        // Icon area with click-to-toggle
        this.prepend(
            <Gtk.Box hexpand={false} vexpand class="icon">
                <Gtk.Image iconName={createBinding(this, "icon")} halign={Gtk.Align.CENTER} />
                <Gtk.GestureClick onReleased={() => {
                    this.state ? this.disable() : this.enable()
                }} />
            </Gtk.Box> as Gtk.Box
        )

        // Content click handler (fires 'clicked' when clicking outside icon area)
        this.add_controller(
            <Gtk.GestureClick onReleased={(_c: Gtk.GestureClick, _n: number, px: number, py: number) => {
                const iconChild = this.get_first_child()
                if (!iconChild) return
                const { x, y, width, height } = iconChild.get_allocation()
                if ((px < x || px > x + width) || (py < y || py > y + height)) {
                    this.emit("clicked")
                }
            }} /> as Gtk.GestureClick
        )

        // Content area (title + description)
        this.append(
            <Gtk.Box class="content" orientation={Gtk.Orientation.VERTICAL}
                vexpand valign={Gtk.Align.CENTER} hexpand>
                <Gtk.Label class="title" label={createBinding(this, "title")}
                    xalign={0} ellipsize={Pango.EllipsizeMode.END} hexpand={false}
                    maxWidthChars={10} />
                <Gtk.Label class="description" label={createBinding(this, "description")}
                    xalign={0} ellipsize={Pango.EllipsizeMode.END}
                    visible={createBinding(this, "description").as((d: string) => d !== "")}
                    maxWidthChars={12} hexpand={false} />
            </Gtk.Box> as Gtk.Box
        )

        // Optional drill-down arrow
        if (this.hasArrow) {
            this.append(
                <Gtk.Image class="arrow" iconName="go-next-symbolic"
                    halign={Gtk.Align.END} /> as Gtk.Image
            )
        }
    }
}
