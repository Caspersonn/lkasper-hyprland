//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
import Quickshell

import "bar"
import "app-launcher"
import "monitor-manager"
import "notifications"
import "osd"

Scope {
    Bar {}

    AppLauncher {}

    MonitorManager {}

    NotificationPopup {}

    OSD {}
}
