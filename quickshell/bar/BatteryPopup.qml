import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../theme"

PopupWindow {
  id: popup

  required property Item anchorItem
  property string fontFamily: "Hack Nerd Font"

  readonly property var battery: UPower.displayDevice
  readonly property bool charging: battery.state === UPowerDeviceState.Charging
  readonly property bool full: battery.state === UPowerDeviceState.FullyCharged
  readonly property int percent: Math.round(battery.percentage * 100)

  function formatDuration(seconds) {
    if (!seconds || seconds <= 0) return "";
    const total = Math.round(seconds / 60);
    const h = Math.floor(total / 60);
    const m = total % 60;
    return h > 0 ? h + " h " + m + " min" : m + " min";
  }

  function formatRate(watts) {
    return (Math.round(Math.abs(watts) * 10) / 10) + " W";
  }

  property int rateInterval: 2000
  property bool sysfsReady: false
  property real sysWatts: 0
  property real sysEnergyNow: 0
  property real sysEnergyFull: 0

  readonly property real watts: sysfsReady ? sysWatts : Math.abs(battery.changeRate)
  readonly property real timeToEmpty: {
    if (!sysfsReady) return battery.timeToEmpty;
    return sysWatts > 0.1 ? sysEnergyNow / sysWatts * 3600 : 0;
  }
  readonly property real timeToFull: {
    if (!sysfsReady) return battery.timeToFull;
    return sysWatts > 0.1 ? Math.max(0, sysEnergyFull - sysEnergyNow) / sysWatts * 3600 : 0;
  }

  Process {
    id: sysfsProc
    command: ["sh", "-c", "for b in /sys/class/power_supply/BAT*; do [ -d \"$b\" ] || continue; echo ---; for f in power_now current_now voltage_now energy_now energy_full charge_now charge_full; do v=$(cat \"$b/$f\" 2>/dev/null) && echo \"$f=$v\"; done; done"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        let watts = 0, now = 0, full = 0, found = false;

        // One block per battery (some laptops have BAT0 + BAT1)
        for (const block of text.split("---").slice(1)) {
          const v = {};
          for (const line of block.trim().split("\n")) {
            const i = line.indexOf("=");
            const n = parseFloat(line.substring(i + 1));
            if (i > 0 && !isNaN(n)) v[line.substring(0, i)] = Math.abs(n);
          }

          const volt = v.voltage_now || 0;
          if (v.power_now !== undefined) watts += v.power_now / 1e6;
          else if (v.current_now !== undefined) watts += v.current_now * volt / 1e12;

          if (v.energy_now !== undefined) {
            now += v.energy_now / 1e6;
            full += (v.energy_full || 0) / 1e6;
          } else if (v.charge_now !== undefined && volt > 0) {
            now += v.charge_now * volt / 1e12;
            full += (v.charge_full || 0) * volt / 1e12;
          } else {
            continue;
          }
          found = true;
        }

        popup.sysWatts = watts;
        popup.sysEnergyNow = now;
        popup.sysEnergyFull = full;
        popup.sysfsReady = found;
      }
    }
  }

  Timer {
    interval: popup.rateInterval
    running: popup.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: sysfsProc.running = true
  }

  anchor.item: anchorItem
  anchor.edges: Edges.Bottom
  anchor.gravity: Edges.Bottom
  grabFocus: true

  implicitWidth: 280
  implicitHeight: card.anchors.topMargin + menuColumn.implicitHeight + 24
  color: "transparent"

  component ProfileItem: Rectangle {
    id: item

    required property int profile
    required property string label
    required property string icon
    readonly property bool selected: PowerProfiles.profile === profile

    Accessible.role: Accessible.RadioButton
    Accessible.name: label
    Accessible.checked: selected

    Layout.fillWidth: true
    implicitHeight: 30
    radius: Theme.radiusMedium
    color: selected ? Theme.surfaceSelected : itemArea.containsMouse ? Theme.surfaceHover : "transparent"

    Behavior on color {
      ColorAnimation { duration: 120 }
    }

    Row {
      anchors.left: parent.left
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      spacing: 10

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: item.icon
        color: item.selected ? Theme.accent : Theme.textSecondary
        font.pixelSize: 14
        font.family: popup.fontFamily
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: item.label
        color: Theme.text
        font.pixelSize: 12
        font.family: popup.fontFamily
      }
    }

    Text {
      anchors.right: parent.right
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      visible: item.selected
      text: "󰄬"
      color: Theme.accent
      font.pixelSize: 14
      font.family: popup.fontFamily
    }

    MouseArea {
      id: itemArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: PowerProfiles.profile = item.profile
    }
  }

  Rectangle {
    id: card
    anchors.fill: parent
    anchors.topMargin: 8
    radius: Theme.radiusLarge
    color: Theme.background
    border.color: Theme.border
    border.width: 1

    focus: true
    Keys.onEscapePressed: popup.visible = false

    ColumnLayout {
      id: menuColumn
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 12
      spacing: 6

      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "Battery"
          color: Theme.text
          font.pixelSize: 13
          font.bold: true
          font.family: popup.fontFamily
        }

        Item { Layout.fillWidth: true }

        Text {
          text: popup.percent + "%"
          color: Theme.textSecondary
          font.pixelSize: 13
          font.family: popup.fontFamily
        }
      }

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 6
        radius: 3
        color: Theme.surface

        Accessible.role: Accessible.ProgressBar
        Accessible.name: "Battery level " + popup.percent + "%"

        Rectangle {
          width: parent.width * Math.max(0, Math.min(1, popup.battery.percentage))
          height: parent.height
          radius: parent.radius
          color: {
            if (popup.charging || popup.full) return Theme.success;
            if (popup.percent > 20) return Theme.accent;
            if (popup.percent > 10) return Theme.warning;
            return Theme.error;
          }

          Behavior on width {
            NumberAnimation { duration: 200 }
          }
        }
      }

      Text {
        Layout.topMargin: 2
        text: "Power source:  " + (UPower.onBattery ? "Battery" : "Power Adapter")
        color: Theme.textSecondary
        font.pixelSize: 11
        font.family: popup.fontFamily
      }

      Text {
        text: {
          if (popup.full) return "Fully charged";
          if (popup.charging) {
            const left = popup.formatDuration(popup.timeToFull);
            return "Charging (" + popup.formatRate(popup.watts) + ")" + (left ? " · full in " + left : "");
          }
          if (popup.battery.state === UPowerDeviceState.Discharging) {
            const left = popup.formatDuration(popup.timeToEmpty);
            return (left ? left + " remaining" : "Discharging") + " (" + popup.formatRate(popup.watts) + ")";
          }
          return "Not charging";
        }
        color: Theme.textSecondary
        font.pixelSize: 11
        font.family: popup.fontFamily
      }

      Text {
        visible: popup.battery.healthSupported
        text: "Health:  " + Math.round(popup.battery.healthPercentage) + "%"
        color: Theme.textSecondary
        font.pixelSize: 11
        font.family: popup.fontFamily
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        implicitHeight: 1
        color: Theme.border
      }

      Text {
        text: "Energy Mode"
        color: Theme.textMuted
        font.pixelSize: 11
        font.bold: true
        font.family: popup.fontFamily
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        ProfileItem {
          visible: PowerProfiles.hasPerformanceProfile
          profile: PowerProfile.Performance
          label: "Performance"
          icon: "󰓅"
        }
        ProfileItem {
          profile: PowerProfile.Balanced
          label: "Balanced"
          icon: "󰾅"
        }
        ProfileItem {
          profile: PowerProfile.PowerSaver
          label: "Power Saver"
          icon: "󰾆"
        }
      }
    }
  }
}
