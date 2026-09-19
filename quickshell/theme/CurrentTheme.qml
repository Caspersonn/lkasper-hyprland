import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property var palette: ({})

    readonly property bool isLight:
        palette.mode === "light"

    function c(name, fallback) {
        let value = palette[name]

        if (value === undefined || value === "")
            value = fallback

        if (!value.startsWith("#"))
            value = "#" + value

        return value
    }

    // Surface colors
    readonly property color bgBase:
        c("base00", "1a1b26")

    readonly property color bgSurface:
        c("base01", "24283b")

    readonly property color bgHover:
        c("base02", "2f334d")

    readonly property color bgSelected:
        c("base02", "283457")

    readonly property color bgBorder:
        c("hairline", palette.base03 ?? "32364a")

    readonly property color bgOverlay:
        isLight ? "#55000000" : "#88000000"

    // Text
    readonly property color textPrimary:
        c("base05", "c0caf5")

    readonly property color textSecondary:
        c("base04", "a9b1d6")

    readonly property color textMuted:
        c("base03", "565f89")

    // Accent colors
    readonly property color accentPrimary:
        c("accent", palette.base0D ?? "7aa2f7")

    readonly property color accentCyan:
        c("base0C", palette.accent ?? "7dcfff")

    readonly property color accentGreen:
        c("base0B", "9ece6a")

    readonly property color accentOrange:
        c("base09", "ff9e64")

    readonly property color accentRed:
        c("base08", "f7768e")

    // Semantic aliases expected by upstream widgets
    readonly property color urgencyLow: textMuted
    readonly property color urgencyNormal: accentPrimary
    readonly property color urgencyCritical: accentRed

    readonly property color batteryGood: accentGreen
    readonly property color batteryWarning: accentOrange
    readonly property color batteryCritical: accentRed

    FileView {
        id: colors

        path:
            Quickshell.env("HOME")
            + "/.config/lkasper-hyprland/current/colors.json"

        blockLoading: true
        watchChanges: true

        onFileChanged: reload()

        onTextChanged: {
            const raw = text()
            if (!raw)
                return

            try {
                root.palette = JSON.parse(raw)
            } catch (error) {
                console.error(
                    "Unable to parse lkasper theme:",
                    error
                )
            }
        }
    }

    // Important because `current` itself is repointed
    // when your lkasper theme changes.
    FileView {
        path:
            Quickshell.env("HOME")
            + "/.config/lkasper-hyprland/state"

        watchChanges: true

        onFileChanged: {
            reload()
            colors.reload()
        }
    }
}
