import { Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import GLib from "gi://GLib"
import Gio from "gi://Gio"
import { closeQuickSettings } from "./index"
import { exec } from "ags/process"

const userFace: Gio.File = Gio.File.new_for_path(`${GLib.get_home_dir()}/.face`)
const uptime = createPoll("", 60000, () => {
    try { return exec("uptime -p") } catch { return "" }
})

function LockButton(): Gtk.Button {
    return <Gtk.Button iconName="system-lock-screen-symbolic"
        tooltipText="Lock"
        onClicked={() => {
            closeQuickSettings()
            exec("hyprlock")
        }}
    /> as Gtk.Button
}

function LogoutButton(): Gtk.Button {
    return <Gtk.Button iconName="system-shutdown-symbolic"
        tooltipText="Logout"
        onClicked={() => {
            closeQuickSettings()
            // TODO: open logout menu window once implemented
        }}
    /> as Gtk.Button
}

export default function QuickActions(): Gtk.Box {
    return <Gtk.Box class="quickactions">
        <Gtk.Box halign={Gtk.Align.START} class="left" hexpand>
            {userFace.query_exists(null) &&
                <Gtk.Box class="user-face"
                    css={`background-image: url("file://${userFace.get_path()!}");`} />
            }
            <Gtk.Box orientation={Gtk.Orientation.VERTICAL}>
                <Gtk.Box class="user-host">
                    <Gtk.Label class="user" xalign={0} label={GLib.get_user_name()} />
                    <Gtk.Label class="host" xalign={0} label={`@${GLib.get_host_name()}`} />
                </Gtk.Box>
                <Gtk.Box>
                    <Gtk.Image iconName="hourglass-symbolic" />
                    <Gtk.Label class="uptime" xalign={0} tooltipText="Up time"
                        label={uptime.as((str: string) => str.replace(/^up /, ""))} />
                </Gtk.Box>
            </Gtk.Box>
        </Gtk.Box>

        <Gtk.Box class="right button-row" halign={Gtk.Align.END} hexpand>
            <LockButton />
            <LogoutButton />
        </Gtk.Box>
    </Gtk.Box> as Gtk.Box
}
