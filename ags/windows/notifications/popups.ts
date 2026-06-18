import GLib from "gi://GLib"
import AstalNotifd from "gi://AstalNotifd"
import { createState } from "ags"

// The AGS shell is the org.freedesktop.Notifications daemon (AstalNotifd).
// This controller drives the transient popup-toast stack: it adds a toast on
// the `notified` signal and removes it on `resolved`, with an urgency-aware
// auto-dismiss timeout, a max-visible cap, and Do Not Disturb suppression.
// It never replays popups for the notifications AstalNotifd restores from its
// on-disk cache at startup — `notified` only fires for genuinely new ones.

const MAX_VISIBLE = 5
const DEFAULT_TIMEOUT_MS = 5000

const [popups, setPopups] = createState<AstalNotifd.Notification[]>([])

// Reactive list of currently-visible toasts, newest first.
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

    // Sticky if critical, or if the app explicitly requested no expiry (0).
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

// Acquire the notification daemon and wire the popup lifecycle. Called from
// app main() so get_default() runs after the GTK app is initialized.
export function initPopups() {
    notifd = AstalNotifd.get_default()

    notifd.connect("notified", (_: any, id: number) => {
        if (notifd!.dontDisturb) return
        const n = notifd!.get_notification(id)
        if (n) addPopup(n)
    })

    notifd.connect("resolved", (_: any, id: number) => {
        removePopup(id)
    })
}
