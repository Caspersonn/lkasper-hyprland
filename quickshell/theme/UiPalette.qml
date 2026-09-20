pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int supportedSchema: 1

    readonly property var colorKeys: [
        "background",
        "surface",
        "foreground",
        "muted",
        "accent",
        "red",
        "yellow",
        "green",
        "blue"
    ]

    readonly property var fallback: ({
        schema: 1,
        mode: "dark",
        background: "#101216",
        surface: "#171a20",
        foreground: "#e6e9ef",
        muted: "#8b93a1",
        accent: "#7aa2f7",
        red: "#f7768e",
        yellow: "#e0af68",
        green: "#9ece6a",
        blue: "#7aa2f7"
    })

    property var active: fallback

    property bool usingFallback: true
    property string lastError: ""

    readonly property string mode: active.mode
    readonly property bool isLight: mode === "light"
    readonly property bool isDark: !isLight

    readonly property color background: active.background
    readonly property color surface: active.surface
    readonly property color foreground: active.foreground
    readonly property color muted: active.muted
    readonly property color accent: active.accent
    readonly property color red: active.red
    readonly property color yellow: active.yellow
    readonly property color green: active.green
    readonly property color blue: active.blue

    function isHexColor(value) {
        return typeof value === "string" && /^#[0-9a-f]{6}$/.test(value);
    }

    function validate(candidate) {
        if (candidate === null || typeof candidate !== "object" || Array.isArray(candidate))
            return "not a JSON object";

        if (candidate.schema !== supportedSchema)
            return "unsupported schema " + JSON.stringify(candidate.schema);

        if (candidate.mode !== "light" && candidate.mode !== "dark")
            return "invalid mode " + JSON.stringify(candidate.mode);

        for (let i = 0; i < colorKeys.length; i++) {
            const key = colorKeys[i];
            if (!isHexColor(candidate[key]))
                return key + " is " + JSON.stringify(candidate[key]) + ", expected lowercase #rrggbb";
        }

        return "";
    }

    function apply(raw) {
        if (!raw) {
            root.lastError = "ui-theme.json is empty or unreadable";
            return false;
        }

        let parsed;
        try {
            parsed = JSON.parse(raw);
        } catch (error) {
            root.lastError = "ui-theme.json is not valid JSON: " + error;
            console.warn("lkh Palette:", root.lastError);
            return false;
        }

        const problem = validate(parsed);
        if (problem !== "") {
            root.lastError = "ui-theme.json rejected: " + problem;
            console.warn("lkh Palette:", root.lastError);
            return false;
        }

        root.active = parsed;
        root.usingFallback = false;
        root.lastError = "";
        return true;
    }

    function reload() {
        paletteFile.reload();
        root.apply(paletteFile.text());
    }

    FileView {
        id: paletteFile

        path: Quickshell.env("HOME") + "/.config/lkasper-hyprland/current/ui-theme.json"

        blockLoading: true
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onTextChanged: root.apply(text())
    }

    FileView {
        id: stateFile

        path: Quickshell.env("HOME") + "/.config/lkasper-hyprland/state"

        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onTextChanged: root.reload()
    }

    Component.onCompleted: root.apply(paletteFile.text())
}
