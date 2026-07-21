import GLib from "gi://GLib"
import AstalNotifd from "gi://AstalNotifd"
import { createState } from "ags"

const MAX_VISIBLE = 5
const DEFAULT_TIMEOUT_MS = 5000

const [popups, setPopups] = createState<AstalNotifd.Notification[]>([])

export const activePopups = popups

let notifd: AstalNotifd.Notifd | null = null
const timers = new Map<number, number>()

function clearTimer(id: number) {
    const t = timers.get(id)
    if (t !== undefined) {
        GLib.source_remove(t)
        timers.delete(id)
    }
}

function removePopup(id: number) {
    clearTimer(id)
    setPopups(popups().filter(n => n.id !== id))
}

function addPopup(n: AstalNotifd.Notification) {
    let next = [n, ...popups().filter(p => p.id !== n.id)]
    if (next.length > MAX_VISIBLE) {
        next.slice(MAX_VISIBLE).forEach(d => clearTimer(d.id))
        next = next.slice(0, MAX_VISIBLE)
    }
    setPopups(next)

    const sticky =
        n.urgency === AstalNotifd.Urgency.CRITICAL || n.expireTimeout === 0
    if (!sticky) {
        const ms = n.expireTimeout > 0 ? n.expireTimeout : DEFAULT_TIMEOUT_MS
        clearTimer(n.id)
        timers.set(
            n.id,
            GLib.timeout_add(GLib.PRIORITY_DEFAULT, ms, () => {
                timers.delete(n.id)
                removePopup(n.id)
                return GLib.SOURCE_REMOVE
            }),
        )
    }
}

export function initPopups() {
    notifd = AstalNotifd.get_default()

    notifd.connect("notified", (_: AstalNotifd.Notifd, id: number) => {
        if (notifd!.dontDisturb) return
        const n = notifd!.get_notification(id)
        if (n) addPopup(n)
    })

    notifd.connect("resolved", (_: AstalNotifd.Notifd, id: number) => {
        removePopup(id)
    })
}
