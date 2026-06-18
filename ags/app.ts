import App from "ags/gtk4/app"
import style from "./style.scss"
import Bars from "./windows/bar"
import Osd from "./windows/osd"
import { initOsd, triggerMedia } from "./windows/osd/controller"
import NotificationPopups from "./windows/notifications"
import { initPopups } from "./windows/notifications/popups"
import NotificationCenter, { initCenter, toggleCenter, toggleDnd } from "./windows/notifications/center"

App.start({
    css: style,
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
        res(`unknown request: ${argv.join(" ")}`)
    },
    main() {
        initCenter()
        Bars()
        Osd()
        initOsd()
        NotificationPopups()
        initPopups()
        NotificationCenter()
    },
})
