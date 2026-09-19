//@ pragma UseQApplication
//@ pragma DefaultEnv QT_QPA_PLATFORMTHEME=gtk3
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
import Quickshell

import "theme"
import "bar"
import "app-launcher"
import "monitor-manager"
import "notifications"
import "osd"

Scope {
    CurrentTheme {
        id: theme
    }

    Bar {
        theme: theme
    }

    AppLauncher {
        theme: theme
    }

    MonitorManager {
        theme: theme
    }

    NotificationPopup {
        theme: theme
    }

    OSD {
        theme: theme
    }
}
