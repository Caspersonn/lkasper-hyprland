import AstalHyprland from "gi://AstalHyprland"
import { createBinding, createComputed, For } from "ags"
import { Gtk } from "ags/gtk4"
import { exec } from "ags/process"

export default function Clients() {
    const hypr = AstalHyprland.get_default()

    const focusedClient = createBinding(hypr, "focusedClient")

  function clientCss(client: AstalHyprland.Client) {
    return createComputed(() => {
      const focused = focusedClient()

      const classes = ["client-button", "clients-separator"]

      if (focused?.class === client.class) {
        classes.push("active")
      }

      return classes
    })
  }

    const uniqueClients = createBinding(hypr, "clients").as(clients => {
        const seen = new Map<string, AstalHyprland.Client>()
        for (const client of clients) {
            if (client.class && client.class !== "") {
                seen.set(client.class, client)
            }
        }
        return Array.from(seen.values())
    })

    return <box class="clients-separator" valign={Gtk.Align.CENTER}>
        <For each={uniqueClients}>
            {client => (
                <button
                    valign={Gtk.Align.CENTER}
                    cssClasses={clientCss(client)}
                    onClicked={() => {
                      exec(`hyprctl keyword cursor:no_warps true`)
                      client.focus()
                      exec(`hyprctl keyword cursor:no_warps false`)
                    }}
                    tooltipText={client.title}
                >
                    <image
                        cssClasses={["client-icon"]}
                        iconName={client.class.toLowerCase()}
                    />
                </button>
            )}
        </For>
    </box>
}
