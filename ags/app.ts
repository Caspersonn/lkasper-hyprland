import App from "ags/gtk4/app"
//import style from "./style.scss"
import Bar from "./windows/bar"
import QuickSettings from "./windows/quick-settings"
import { initTheme, loadTheme, getCurrentTheme, getThemeList, nextWallpaper } from "./services/theme"

App.start({
    //css: style,
    requestHandler(argv: string[], response: (msg: string) => void) {
        const parts = argv.flatMap(a => a.split(/\s+/))
        const cmd = parts[0]

        if (cmd === "theme") {
            const action = parts[1]
            if (action === "set" && parts[2]) {
                const success = loadTheme(parts[2])
                response(success ? `Theme set to ${parts[2]}` : `Failed to set theme ${parts[2]}`)
            } else if (action === "get") {
                response(getCurrentTheme())
            } else if (action === "list") {
                response(getThemeList().join("\n"))
            } else {
                response("Usage: theme set <name> | theme get | theme list")
            }
        } else if (cmd === "wallpaper") {
            const action = parts[1]
            if (action === "next") {
                const success = nextWallpaper()
                response(success ? "Wallpaper cycled" : "Failed to cycle wallpaper")
            } else {
                response("Usage: wallpaper next")
            }
        } else {
            response(`Unknown command: ${cmd}`)
        }
    },
    main() {
        initTheme()
        Bar()
        QuickSettings()
    },
})
