import { Gtk } from "ags/gtk4"

export function isInside(widget: Gtk.Widget | null, ancestor: Gtk.Widget | null): boolean {
    let w = widget
    while (w) {
        if (w === ancestor) return true
        w = w.get_parent()
    }
    return false
}

export function styledPopover(content: Gtk.Widget): Gtk.Popover {
    const pop = new Gtk.Popover()
    pop.set_has_arrow(false)
    pop.add_css_class("popover-wrap")
    pop.set_child(content)
    return pop
}

export const pad = (n: number) => String(n).padStart(2, "0")
