import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "../theme"

// Bluetooth power toggle + device list, opened from the bluetooth pill.
// Based on https://github.com/luyu-wu/Config/blob/Laptop/quickshell/popups/bluetooth/BluetoothPopup.qml
PopupWindow {
  id: popup

  required property Item anchorItem
  property string fontFamily: "Hack Nerd Font"

  readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
  readonly property bool powered: adapter !== null && adapter.enabled
  readonly property var devices: adapter ? adapter.devices.values : []
  readonly property var pairedDevices: devices.filter(d => d.paired)
  // Unpaired devices without a real name are mostly noise (beacons, TVs, ...)
  readonly property var availableDevices: devices.filter(d => !d.paired && d.deviceName)

  function deviceGlyph(icon) {
    const name = icon || "";
    if (name.startsWith("audio-head")) return "󰋋";
    if (name.startsWith("audio")) return "󰓃";
    if (name === "input-mouse") return "󰍽";
    if (name === "input-keyboard") return "󰌌";
    if (name === "input-gaming") return "󰊗";
    if (name.startsWith("phone")) return "󰏲";
    return "󰂯";
  }

  function deviceStatus(device) {
    if (device.pairing) return "Pairing…";
    switch (device.state) {
    case BluetoothDeviceState.Connecting: return "Connecting…";
    case BluetoothDeviceState.Disconnecting: return "Disconnecting…";
    case BluetoothDeviceState.Connected:
      return device.batteryAvailable ? "Connected · " + Math.round(device.battery * 100) + "%" : "Connected";
    }
    return device.paired ? "Not connected" : "";
  }

  anchor.item: anchorItem
  anchor.edges: Edges.Bottom
  anchor.gravity: Edges.Bottom
  // Clicking outside the popup dismisses it
  grabFocus: true

  implicitWidth: 320
  implicitHeight: card.anchors.topMargin + menuColumn.implicitHeight + 24
  color: "transparent"

  // Only scan for nearby devices while the popup is open
  onVisibleChanged: if (powered) adapter.discovering = visible

  Connections {
    target: popup.adapter
    function onEnabledChanged() {
      if (popup.adapter.enabled && popup.visible) popup.adapter.discovering = true;
    }
  }

  component Divider: Rectangle {
    Layout.fillWidth: true
    Layout.topMargin: 4
    Layout.bottomMargin: 4
    implicitHeight: 1
    color: Theme.border
  }

  component SectionLabel: Text {
    color: Theme.textMuted
    font.pixelSize: 11
    font.bold: true
    font.family: popup.fontFamily
  }

  component DeviceItem: Rectangle {
    id: item

    required property BluetoothDevice device
    readonly property string status: popup.deviceStatus(device)
    readonly property bool busy: device.pairing
      || device.state === BluetoothDeviceState.Connecting
      || device.state === BluetoothDeviceState.Disconnecting

    Accessible.role: Accessible.Button
    Accessible.name: nameText.text + (status ? ", " + status : "")

    Layout.fillWidth: true
    implicitHeight: 38
    radius: Theme.radiusMedium
    color: device.connected ? Theme.surfaceSelected : itemArea.containsMouse ? Theme.surfaceHover : "transparent"

    Behavior on color {
      ColorAnimation { duration: 120 }
    }

    Text {
      id: glyph
      anchors.left: parent.left
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      width: 18
      text: popup.deviceGlyph(item.device.icon)
      color: item.device.connected ? Theme.accent : Theme.textSecondary
      font.pixelSize: 16
      font.family: popup.fontFamily
    }

    Column {
      anchors.left: glyph.right
      anchors.leftMargin: 10
      anchors.right: parent.right
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      spacing: 1

      Text {
        id: nameText
        width: parent.width
        text: item.device.name || item.device.deviceName || item.device.address
        color: Theme.text
        font.pixelSize: 12
        font.family: popup.fontFamily
        elide: Text.ElideRight
      }

      Text {
        visible: text !== ""
        text: item.status
        color: item.busy ? Theme.accent : Theme.textMuted
        font.pixelSize: 10
        font.family: popup.fontFamily
      }
    }

    MouseArea {
      id: itemArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: item.busy ? Qt.BusyCursor : Qt.PointingHandCursor
      onClicked: {
        if (item.busy) return;
        if (item.device.connected) item.device.disconnect();
        else item.device.connect();
      }
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

      // Header
      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "Bluetooth"
          color: Theme.text
          font.pixelSize: 13
          font.bold: true
          font.family: popup.fontFamily
        }

        Item { Layout.fillWidth: true }

        // Power switch
        Rectangle {
          visible: popup.adapter !== null
          implicitWidth: 40
          implicitHeight: 22
          radius: 11
          color: popup.powered ? Theme.accent : Theme.surfaceHover

          Accessible.role: Accessible.CheckBox
          Accessible.name: "Bluetooth"
          Accessible.checked: popup.powered

          Behavior on color {
            ColorAnimation { duration: 160; easing.type: Easing.InOutQuad }
          }

          Rectangle {
            x: popup.powered ? parent.width - width - 2 : 2
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 18
            radius: 9
            color: popup.powered ? Theme.background : Theme.textSecondary

            Behavior on x {
              NumberAnimation { duration: 160; easing.type: Easing.InOutQuad }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.adapter.enabled = !popup.adapter.enabled
          }
        }
      }

      Text {
        visible: !popup.powered
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        text: popup.adapter ? "Bluetooth is off" : "No Bluetooth adapter found"
        color: Theme.textMuted
        font.pixelSize: 11
        font.family: popup.fontFamily
      }

      Divider { visible: popup.powered }

      // Paired devices
      SectionLabel {
        visible: popup.powered && popup.pairedDevices.length > 0
        text: "Paired"
      }

      Repeater {
        model: popup.powered ? popup.pairedDevices : []

        DeviceItem {
          required property var modelData
          device: modelData
        }
      }

      // Nearby devices
      RowLayout {
        visible: popup.powered
        Layout.fillWidth: true
        Layout.topMargin: popup.pairedDevices.length > 0 ? 4 : 0

        SectionLabel { text: "Available" }

        Item { Layout.fillWidth: true }

        Text {
          visible: popup.adapter !== null && popup.adapter.discovering
          text: "Scanning…"
          color: Theme.textMuted
          font.pixelSize: 10
          font.family: popup.fontFamily
        }
      }

      Repeater {
        model: popup.powered ? popup.availableDevices : []

        DeviceItem {
          required property var modelData
          device: modelData
        }
      }

      Text {
        visible: popup.powered && popup.availableDevices.length === 0
        Layout.leftMargin: 10
        text: "No devices found"
        color: Theme.textMuted
        font.pixelSize: 11
        font.family: popup.fontFamily
      }

      Divider {}

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 30
        radius: Theme.radiusMedium
        color: settingsArea.containsMouse ? Theme.surfaceHover : "transparent"

        Accessible.role: Accessible.Button
        Accessible.name: "Bluetooth settings"

        Text {
          anchors.left: parent.left
          anchors.leftMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          text: "Bluetooth Settings…"
          color: Theme.text
          font.pixelSize: 12
          font.family: popup.fontFamily
        }

        MouseArea {
          id: settingsArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            Quickshell.execDetached(["blueman-manager"]);
            popup.visible = false;
          }
        }
      }
    }
  }
}
