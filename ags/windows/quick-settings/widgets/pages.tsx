import { Gtk } from "ags/gtk4"
import { register } from "ags/gobject"
import { Page } from "./page"
import GLib from "gi://GLib"

@register({ GTypeName: "LkhPages" })
export class Pages extends Gtk.Box {
    #page: Page | undefined
    #transDuration: number
    #timeouts: Array<[number, (() => void) | undefined]> = []

    get isOpen(): boolean { return Boolean(this.#page) }
    get page(): Page | undefined { return this.#page }

    constructor(props?: { transitionDuration?: number }) {
        super({
            orientation: Gtk.Orientation.VERTICAL,
            name: "pages",
        })
        this.add_css_class("pages")
        this.#transDuration = props?.transitionDuration ?? 280

        this.connect("destroy", () => {
            for (const [id, cb] of this.#timeouts) {
                GLib.source_remove(id)
                try { cb?.() } catch (e: any) {
                    console.error(`${e.message}\n${e.stack}`)
                }
            }
        })
    }

    toggle(newPage?: Page, onToggled?: () => void): void {
        if (!newPage || this.#page?.id === newPage.id) {
            this.close(onToggled)
            return
        }

        if (!this.isOpen) {
            if (newPage) this.open(newPage, onToggled)
            return
        }

        if (this.#page?.id !== newPage.id) {
            this.close()
            this.open(newPage, onToggled)
        }
    }

    open(newPage: Page, onOpen?: () => void): void {
        this.#page = newPage

        const revealer = <Gtk.Revealer
            revealChild={false}
            transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
            transitionDuration={this.#transDuration}>
            {newPage.create()}
        </Gtk.Revealer> as Gtk.Revealer

        this.prepend(revealer)
        revealer.set_reveal_child(true)
        newPage.actionOpen?.()
        onOpen?.()
    }

    close(onClosed?: () => void): void {
        const revealer = this.get_first_child() as Gtk.Revealer | null
        if (!revealer) return

        this.#page?.actionClosed?.()
        this.#page = undefined

        revealer.set_reveal_child(false)

        const timeoutId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, revealer.transitionDuration, () => {
            this.remove(revealer)
            onClosed?.()
            return GLib.SOURCE_REMOVE
        })
        this.#timeouts.push([timeoutId, onClosed])
    }
}
