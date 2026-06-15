import App from "ags/gtk4/app"
import style from "./style.scss"
import Bars from "./windows/bar"
import Osd from "./windows/osd"
import { initOsd, triggerMedia } from "./windows/osd/controller"

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
        res(`unknown request: ${argv.join(" ")}`)
    },
    main() {
        Bars()
        Osd()
        initOsd()
    },
})
