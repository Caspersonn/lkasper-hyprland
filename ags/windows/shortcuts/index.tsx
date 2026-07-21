import Gdk from "gi://Gdk"
import AstalHyprland from "gi://AstalHyprland"
import App from "ags/gtk4/app"
import { For, createBinding, createComputed, createState } from "ags"
import { Astal, Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"

interface HyprBind {
    modmask: number
    key: string
    dispatcher: string
    arg: string
    description: string
    has_description: boolean
}

interface Row {
    key: string
    label: string
    chips: string[]
}

interface Group {
    name: string
    rows: Row[]
}

interface Column {
    id: number
    groups: Group[]
}

const [visible, setVisible] = createState(false)
const [connector, setConnector] = createState<string | null>(null)
const [columns, setColumns] = createState<Column[]>([])

const hypr = AstalHyprland.get_default()

const MOD_CHIPS: [number, string][] = [
    [64, "Super"],
    [4, "Ctrl"],
    [8, "Alt"],
    [1, "Shift"],
]

const KEY_MAP: Record<string, string> = {
    slash: "/",
    Return: "⏎",
    Escape: "Esc",
    Backspace: "⌫",
    left: "←",
    right: "→",
    up: "↑",
    down: "↓",
    minus: "-",
    equal: "=",
    comma: ",",
    period: ".",
    space: "Space",
    PRINT: "Print",
    Print: "Print",
}

function prettifyKey(k: string): string {
    return KEY_MAP[k] ?? (k.length === 1 ? k.toUpperCase() : k)
}

function modChips(mask: number): string[] {
    return MOD_CHIPS.filter(([bit]) => (mask & bit) !== 0).map(([, name]) => name)
}

function parseDesc(desc: string): { group: string; label: string } {
    const m = desc.match(/^\[([^\]]+)\]\s*(.*)$/)
    if (m) return { group: m[1], label: m[2] }
    return { group: "Other", label: desc }
}

function buildGroups(binds: HyprBind[]): Group[] {
    const described = binds.filter((b) => b.has_description && b.description)

    const order: string[] = []
    const byGroup = new Map<string, HyprBind[]>()
    for (const b of described) {
        const { group } = parseDesc(b.description)
        if (!byGroup.has(group)) {
            byGroup.set(group, [])
            order.push(group)
        }
        byGroup.get(group)!.push(b)
    }

    return order.map((name) => {
        const items = byGroup.get(name)!
        const rows: Row[] = []
        const used = new Set<number>()

        for (let i = 0; i < items.length; i++) {
            if (used.has(i)) continue
            const b = items[i]
            const { label } = parseDesc(b.description)

            if (/^[0-9]$/.test(b.key)) {
                const mates: HyprBind[] = []
                for (let j = i; j < items.length; j++) {
                    const c = items[j]
                    if (
                        !used.has(j) &&
                        /^[0-9]$/.test(c.key) &&
                        c.modmask === b.modmask &&
                        c.dispatcher === b.dispatcher &&
                        parseDesc(c.description).label === label
                    ) {
                        mates.push(c)
                        used.add(j)
                    }
                }
                if (mates.length > 1) {
                    const first = prettifyKey(mates[0].key)
                    const last = prettifyKey(mates[mates.length - 1].key)
                    rows.push({
                        key: `${name}-${label}-${b.modmask}-range`,
                        label,
                        chips: [...modChips(b.modmask), `${first} – ${last}`],
                    })
                    continue
                }
            }

            used.add(i)
            rows.push({
                key: `${name}-${b.modmask}-${b.key}`,
                label,
                chips: [...modChips(b.modmask), prettifyKey(b.key)],
            })
        }

        return { name, rows }
    })
}

function toColumns(groups: Group[], n = 2): Column[] {
    const cols = Array.from({ length: n }, (_, i) => ({
        id: i,
        groups: [] as Group[],
        weight: 0,
    }))
    for (const g of groups) {
        const target = cols.reduce((a, b) => (a.weight <= b.weight ? a : b))
        target.groups.push(g)
        target.weight += g.rows.length + 1
    }
    return cols
        .filter((c) => c.groups.length > 0)
        .map((c) => ({ id: c.id, groups: c.groups }))
}

async function refresh() {
    try {
        const out = await execAsync(["hyprctl", "binds", "-j"])
        const binds = JSON.parse(out) as HyprBind[]
        setColumns(toColumns(buildGroups(binds)))
    } catch {
        setColumns([])
    }
}

export function toggleShortcuts() {
    if (visible()) {
        setVisible(false)
        return
    }
    const fm = hypr.focusedMonitor
    setConnector(fm ? fm.name : null)
    void refresh()
    setVisible(true)
}

function ShortcutsWindow(gdkmonitor: Gdk.Monitor) {
    const myConnector = gdkmonitor.get_connector() ?? "unknown"
    const winVisible = createComputed(
        () => visible() && connector() === myConnector,
    )

    const keys = new Gtk.EventControllerKey()
    keys.connect("key-pressed", (_c, keyval) => {
        if (keyval === Gdk.KEY_Escape) {
            setVisible(false)
            return true
        }
        return false
    })

    const backdropClick = new Gtk.GestureClick()
    backdropClick.connect("pressed", () => setVisible(false))
    const cardClick = new Gtk.GestureClick()
    cardClick.connect("pressed", () =>
        cardClick.set_state(Gtk.EventSequenceState.CLAIMED),
    )

    return <window
        name={`shortcuts-${myConnector}`}
        namespace="shortcuts"
        application={App}
        gdkmonitor={gdkmonitor}
        class="shortcuts"
        layer={Astal.Layer.OVERLAY}
        anchor={
            Astal.WindowAnchor.TOP |
            Astal.WindowAnchor.BOTTOM |
            Astal.WindowAnchor.LEFT |
            Astal.WindowAnchor.RIGHT
        }
        exclusivity={Astal.Exclusivity.IGNORE}
        keymode={Astal.Keymode.EXCLUSIVE}
        visible={winVisible}
        $={(self) => self.add_controller(keys)}
    >
        <box
            class="sc-backdrop"
            hexpand
            vexpand
            halign={Gtk.Align.FILL}
            valign={Gtk.Align.FILL}
            $={(self) => self.add_controller(backdropClick)}
        >
            <box
                class="sc-modal"
                orientation={Gtk.Orientation.VERTICAL}
                halign={Gtk.Align.CENTER}
                valign={Gtk.Align.CENTER}
                $={(self) => self.add_controller(cardClick)}
            >
                <label class="sc-title" xalign={0} label="Keyboard shortcuts" />
                <box class="sc-columns" valign={Gtk.Align.START}>
                    <For each={columns} id={(c: Column) => String(c.id)}>
                        {(col: Column) => (
                            <box
                                class="sc-column"
                                orientation={Gtk.Orientation.VERTICAL}
                            >
                                {col.groups.map((g) => (
                                    <box
                                        class="sc-group"
                                        orientation={Gtk.Orientation.VERTICAL}
                                    >
                                        <label
                                            class="sc-group-title"
                                            xalign={0}
                                            label={g.name}
                                        />
                                        {g.rows.map((r) => (
                                            <box class="sc-row">
                                                <label
                                                    class="sc-row-label"
                                                    xalign={0}
                                                    hexpand
                                                    label={r.label}
                                                />
                                                <box
                                                    class="sc-chips"
                                                    halign={Gtk.Align.END}
                                                    valign={Gtk.Align.CENTER}
                                                >
                                                    {r.chips.map((c) => (
                                                        <label
                                                            class="sc-key"
                                                            label={c}
                                                        />
                                                    ))}
                                                </box>
                                            </box>
                                        ))}
                                    </box>
                                ))}
                            </box>
                        )}
                    </For>
                </box>
            </box>
        </box>
    </window>
}

export function initShortcuts() {
    const monitors = createBinding(App, "monitors")
    return (
        <For each={monitors} cleanup={(win) => (win as Gtk.Window).destroy()}>
            {(monitor: Gdk.Monitor) => ShortcutsWindow(monitor)}
        </For>
    )
}
