import App from "ags/gtk4/app"
import style from "./style.scss"
import Bar from "./windows/bar"

App.start({
    css: style,
    main() {
        Bar()
    },
})
