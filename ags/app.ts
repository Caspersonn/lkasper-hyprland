import App from "ags/gtk4/app"
import Bars from "./windows/bar"
import Osd from "./windows/osd"
import { initOsd, triggerMedia } from "./windows/osd/controller"
import NotificationPopups from "./windows/notifications"
import { initPopups } from "./windows/notifications/popups"
import { initCenter, toggleCenter, toggleDnd } from "./windows/notifications/center"
import { initShortcuts, toggleShortcuts } from "./windows/shortcuts"
import { initLauncher, toggleLauncher } from "./windows/launcher"
import { initSoltty, toggleSoltty } from "./windows/soltty"
import { initSolttyService } from "./windows/soltty/service"
import { themedCss, watchTheme } from "./theme"

App.start({
    // Full themed stylesheet (wallpaper palette @define-colors + rules); rebuilt
    // live on a wallpaper switch by watchTheme().
    css: themedCss(),
    requestHandler(argv, res) {
        if (argv.includes("toggle-bars")) {
            for (const win of App.get_windows()) {
                if (win.name?.startsWith("bar")) {
                    win.visible = !win.visible
                }
            }
            res("ok")
            return
        }
        if (argv[0] === "osd-media") {
            triggerMedia(argv[1] ?? "playpause")
            res("ok")
            return
        }
        if (argv.includes("toggle-notifications")) {
            toggleCenter()
            res("ok")
            return
        }
        if (argv.includes("toggle-dnd")) {
            toggleDnd()
            res("ok")
            return
        }
        if (argv.includes("toggle-shortcuts")) {
            toggleShortcuts()
            res("ok")
            return
        }
        if (argv.includes("toggle-launcher")) {
            toggleLauncher()
            res("ok")
            return
        }
        if (argv.includes("toggle-soltty")) {
            toggleSoltty()
            res("ok")
            return
        }
        res(`unknown request: ${argv.join(" ")}`)
    },
    main() {
        watchTheme()
        initCenter()
        Bars()
        Osd()
        initOsd()
        NotificationPopups()
        initPopups()
        initShortcuts()
        initLauncher()
        initSolttyService()
        initSoltty()
    },
})
