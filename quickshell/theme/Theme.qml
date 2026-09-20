pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string mode: UiPalette.mode
    readonly property bool isLight: UiPalette.isLight
    readonly property bool isDark: UiPalette.isDark

    function alpha(base, amount) {
        return Qt.rgba(base.r, base.g, base.b, amount);
    }

    function mix(from, to, amount) {
        return Qt.rgba(from.r + (to.r - from.r) * amount, from.g + (to.g - from.g) * amount, from.b + (to.b - from.b) * amount, from.a + (to.a - from.a) * amount);
    }

    readonly property color contrastPole: isLight ? "#000000" : "#ffffff"
    readonly property color shadowPole: "#000000"

    readonly property color background: UiPalette.background
    readonly property color surface: UiPalette.surface
    readonly property color surfaceRaised: mix(surface, contrastPole, isLight ? 0.04 : 0.06)
    readonly property color surfaceHover: mix(surface, contrastPole, isLight ? 0.07 : 0.10)
    readonly property color surfaceSelected: mix(surface, UiPalette.accent, isLight ? 0.14 : 0.18)
    readonly property color overlay: alpha(shadowPole, isLight ? 0.20 : 0.45)

    readonly property color text: UiPalette.foreground
    readonly property color textSecondary: mix(UiPalette.foreground, UiPalette.muted, 0.55)
    readonly property color textMuted: UiPalette.muted
    readonly property color textDisabled: mix(UiPalette.muted, surface, 0.45)

    readonly property color border: alpha(UiPalette.foreground, isLight ? 0.14 : 0.09)
    readonly property color borderStrong: alpha(UiPalette.foreground, isLight ? 0.28 : 0.20)

    readonly property color accent: UiPalette.accent
    readonly property color accentHover: mix(UiPalette.accent, contrastPole, 0.16)
    readonly property color accentMuted: alpha(UiPalette.accent, isLight ? 0.18 : 0.22)

    readonly property color success: UiPalette.green
    readonly property color warning: UiPalette.yellow
    readonly property color error: UiPalette.red
    readonly property color info: UiPalette.blue

    readonly property color shadow: alpha(shadowPole, isLight ? 0.12 : 0.32)

    readonly property int radiusSmall: 4
    readonly property int radiusMedium: 8
    readonly property int radiusLarge: 14

    readonly property int spacingSmall: 4
    readonly property int spacingMedium: 8
    readonly property int spacingLarge: 16

    readonly property color bgBase: background
    readonly property color bgSurface: surface
    readonly property color bgOverlay: overlay
    readonly property color bgHover: surfaceHover
    readonly property color bgSelected: surfaceSelected
    readonly property color bgBorder: border

    readonly property color textPrimary: text

    readonly property color accentPrimary: accent
    readonly property color accentCyan: info
    readonly property color accentGreen: success
    readonly property color accentOrange: warning
    readonly property color accentRed: error

    readonly property color urgencyLow: textMuted
    readonly property color urgencyNormal: accent
    readonly property color urgencyCritical: error

    readonly property color batteryGood: success
    readonly property color batteryWarning: warning
    readonly property color batteryCritical: error
}
