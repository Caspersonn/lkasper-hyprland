import App from "ags/gtk4/app"
import style from "./style.scss"
import Bar from "./windows/bar"
import QuickSettings from "./windows/QuickSettings/quick-settings"

App.start({
  css: style,
    main() {
        Bar()
        QuickSettings()
    },
})
