import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import "../theme"

// Wi-Fi toggle + network list, opened from the network pill.
// Based on https://github.com/luyu-wu/Config/blob/Laptop/quickshell/popups/network/NetworkPopup.qml
PopupWindow {
  id: popup

  required property Item anchorItem
  property string fontFamily: "Hack Nerd Font"

  readonly property WifiDevice wifiDev: {
    for (const d of Networking.devices.values) {
      if (d.type === DeviceType.Wifi) return d;
    }
    return null;
  }
  readonly property bool wifiOn: wifiDev !== null && Networking.wifiEnabled
  // Connected first, then saved networks, then by signal strength.
  // Hidden networks have no SSID to connect to, so they are left out.
  readonly property var networks: {
    if (!wifiOn) return [];
    return wifiDev.networks.values
      .filter(n => n.name)
      .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength));
  }

  // Network waiting for a password, shown in the password field below the list
  property WifiNetwork pskNetwork: null
  // Last network we tried to connect to, so failures can be reported
  property WifiNetwork pendingNetwork: null
  property string errorText: ""

  function isSecured(network) {
    return network.security !== WifiSecurityType.Open;
  }

  function signalGlyph(strength) {
    if (strength > 0.75) return String.fromCodePoint(0xF0928); // nf-md-wifi_strength_4
    if (strength > 0.50) return String.fromCodePoint(0xF0925); // nf-md-wifi_strength_3
    if (strength > 0.25) return String.fromCodePoint(0xF0922); // nf-md-wifi_strength_2
    if (strength > 0.05) return String.fromCodePoint(0xF091F); // nf-md-wifi_strength_1
    return String.fromCodePoint(0xF092F); // nf-md-wifi_strength_outline
  }

  function networkStatus(network) {
    switch (network.state) {
    case ConnectionState.Connecting: return "Connecting…";
    case ConnectionState.Disconnecting: return "Disconnecting…";
    case ConnectionState.Connected: return "Connected";
    }
    if (network.known) return "Saved";
    return isSecured(network) ? "Secured" : "Open";
  }

  function activate(network) {
    errorText = "";
    if (network.connected) {
      network.disconnect();
      return;
    }
    // Without a polkit/NM secret agent, an unknown secured network can only
    // be joined by handing NetworkManager the password ourselves.
    if (!network.known && isSecured(network)) {
      pskNetwork = network;
      return;
    }
    pskNetwork = null;
    pendingNetwork = network;
    network.connect();
  }

  function submitPsk(psk) {
    if (!pskNetwork || psk === "") return;
    pendingNetwork = pskNetwork;
    pskNetwork.connectWithPsk(psk);
    pskNetwork = null;
  }

  anchor.item: anchorItem
  anchor.edges: Edges.Bottom
  anchor.gravity: Edges.Bottom
  // Clicking outside the popup dismisses it
  grabFocus: true

  implicitWidth: 320
  implicitHeight: card.anchors.topMargin + menuColumn.implicitHeight + 24
  color: "transparent"

  // Only scan for networks while the popup is open
  onVisibleChanged: {
    if (wifiDev) wifiDev.scannerEnabled = visible && Networking.wifiEnabled;
    if (!visible) {
      pskNetwork = null;
      errorText = "";
    }
  }

  onPskNetworkChanged: {
    pskInput.text = "";
    if (pskNetwork) pskInput.forceActiveFocus();
    else card.forceActiveFocus();
  }

  Connections {
    target: Networking
    function onWifiEnabledChanged() {
      if (popup.wifiDev) popup.wifiDev.scannerEnabled = popup.visible && Networking.wifiEnabled;
    }
  }

  Connections {
    target: popup.pendingNetwork
    function onConnectionFailed(reason) {
      const network = popup.pendingNetwork;
      if (reason === ConnectionFailReason.NoSecrets && popup.isSecured(network)) {
        // Saved password missing or rejected: ask for a new one
        popup.errorText = "Password required for " + network.name;
        popup.pskNetwork = network;
      } else if (reason === ConnectionFailReason.WifiNetworkLost) {
        popup.errorText = "Lost " + network.name;
      } else {
        popup.errorText = "Could not connect to " + network.name;
      }
      popup.pendingNetwork = null;
    }
    function onConnectedChanged() {
      if (popup.pendingNetwork.connected) popup.pendingNetwork = null;
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

  component TextButton: Rectangle {
    id: button

    property string label
    property bool primary: false
    signal clicked()

    Accessible.role: Accessible.Button
    Accessible.name: label

    implicitWidth: buttonText.implicitWidth + 20
    implicitHeight: 26
    radius: Theme.radiusMedium
    color: primary
      ? (buttonArea.containsMouse ? Theme.accentHover : Theme.accent)
      : (buttonArea.containsMouse ? Theme.surfaceHover : "transparent")

    Text {
      id: buttonText
      anchors.centerIn: parent
      text: button.label
      color: button.primary ? Theme.background : Theme.text
      font.pixelSize: 11
      font.bold: button.primary
      font.family: popup.fontFamily
    }

    MouseArea {
      id: buttonArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: button.clicked()
    }
  }

  component NetworkItem: Rectangle {
    id: item

    required property WifiNetwork network
    readonly property string status: popup.networkStatus(network)
    readonly property bool busy: network.stateChanging
      || network.state === ConnectionState.Connecting
      || network.state === ConnectionState.Disconnecting

    Accessible.role: Accessible.Button
    Accessible.name: network.name + ", " + status

    implicitHeight: 38
    radius: Theme.radiusMedium
    color: network.connected ? Theme.surfaceSelected : itemHover.hovered ? Theme.surfaceHover : "transparent"

    Behavior on color {
      ColorAnimation { duration: 120 }
    }

    HoverHandler { id: itemHover }

    MouseArea {
      anchors.fill: parent
      cursorShape: item.busy ? Qt.BusyCursor : Qt.PointingHandCursor
      onClicked: if (!item.busy) popup.activate(item.network)
    }

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 10
      anchors.rightMargin: 10
      spacing: 10

      Text {
        Layout.preferredWidth: 18
        text: popup.signalGlyph(item.network.signalStrength)
        color: item.network.connected ? Theme.accent : Theme.textSecondary
        font.pixelSize: 16
        font.family: popup.fontFamily
      }

      Column {
        Layout.fillWidth: true
        spacing: 1

        Text {
          width: parent.width
          text: item.network.name
          color: Theme.text
          font.pixelSize: 12
          font.family: popup.fontFamily
          elide: Text.ElideRight
        }

        Text {
          text: item.status
          color: item.busy ? Theme.accent : Theme.textMuted
          font.pixelSize: 10
          font.family: popup.fontFamily
        }
      }

      // Forget a saved network
      Text {
        visible: item.network.known && itemHover.hovered && !item.busy
        text: String.fromCodePoint(0xF01B4) // nf-md-delete
        color: forgetArea.containsMouse ? Theme.error : Theme.textMuted
        font.pixelSize: 14
        font.family: popup.fontFamily

        Accessible.role: Accessible.Button
        Accessible.name: "Forget " + item.network.name

        MouseArea {
          id: forgetArea
          anchors.fill: parent
          anchors.margins: -4
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: item.network.forget()
        }
      }

      Text {
        visible: popup.isSecured(item.network)
        text: String.fromCodePoint(0xF033E) // nf-md-lock
        color: Theme.textMuted
        font.pixelSize: 12
        font.family: popup.fontFamily
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
          text: "Wi-Fi"
          color: Theme.text
          font.pixelSize: 13
          font.bold: true
          font.family: popup.fontFamily
        }

        Item { Layout.fillWidth: true }

        // Wi-Fi switch
        Rectangle {
          visible: popup.wifiDev !== null
          implicitWidth: 40
          implicitHeight: 22
          radius: 11
          color: popup.wifiOn ? Theme.accent : Theme.surfaceHover

          Accessible.role: Accessible.CheckBox
          Accessible.name: "Wi-Fi"
          Accessible.checked: popup.wifiOn

          Behavior on color {
            ColorAnimation { duration: 160; easing.type: Easing.InOutQuad }
          }

          Rectangle {
            x: popup.wifiOn ? parent.width - width - 2 : 2
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 18
            radius: 9
            color: popup.wifiOn ? Theme.background : Theme.textSecondary

            Behavior on x {
              NumberAnimation { duration: 160; easing.type: Easing.InOutQuad }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
          }
        }
      }

      Text {
        visible: !popup.wifiOn
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        text: {
          if (!popup.wifiDev) return "No Wi-Fi adapter found";
          if (!Networking.wifiHardwareEnabled) return "Wi-Fi is blocked (airplane mode)";
          return "Wi-Fi is off";
        }
        color: Theme.textMuted
        font.pixelSize: 11
        font.family: popup.fontFamily
      }

      Divider { visible: popup.wifiOn }

      RowLayout {
        visible: popup.wifiOn
        Layout.fillWidth: true

        SectionLabel { text: "Networks" }

        Item { Layout.fillWidth: true }

        Text {
          visible: popup.wifiDev !== null && popup.wifiDev.scannerEnabled
          text: "Scanning…"
          color: Theme.textMuted
          font.pixelSize: 10
          font.family: popup.fontFamily
        }
      }

      // Scrolls once there are more than ~8 networks
      ListView {
        id: networkList
        visible: popup.wifiOn && count > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 8 * 38 + 7 * spacing)
        spacing: 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: popup.networks

        delegate: NetworkItem {
          required property var modelData
          width: ListView.view.width
          network: modelData
        }
      }

      Text {
        visible: popup.wifiOn && popup.networks.length === 0
        Layout.leftMargin: 10
        text: "No networks found"
        color: Theme.textMuted
        font.pixelSize: 11
        font.family: popup.fontFamily
      }

      Text {
        visible: popup.errorText !== ""
        Layout.fillWidth: true
        Layout.leftMargin: 10
        text: popup.errorText
        color: Theme.error
        font.pixelSize: 11
        font.family: popup.fontFamily
        wrapMode: Text.Wrap
      }

      // Password prompt for secured networks
      ColumnLayout {
        visible: popup.pskNetwork !== null
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 6

        SectionLabel {
          Layout.fillWidth: true
          text: popup.pskNetwork ? "Password for " + popup.pskNetwork.name : ""
          elide: Text.ElideRight
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 30
          radius: Theme.radiusMedium
          color: Theme.surface
          border.width: 1
          border.color: pskInput.activeFocus ? Theme.accent : Theme.border

          TextInput {
            id: pskInput
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            echoMode: showPsk.checked ? TextInput.Normal : TextInput.Password
            color: Theme.text
            selectionColor: Theme.accentMuted
            font.pixelSize: 12
            font.family: popup.fontFamily
            clip: true

            Accessible.role: Accessible.EditableText
            Accessible.name: "Wi-Fi password"

            onAccepted: popup.submitPsk(text)
            Keys.onEscapePressed: popup.pskNetwork = null

            Text {
              anchors.verticalCenter: parent.verticalCenter
              visible: pskInput.text === ""
              text: "Password"
              color: Theme.textDisabled
              font: pskInput.font
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 6

          TextButton {
            id: showPsk
            property bool checked: false
            label: checked ? "Hide" : "Show"
            onClicked: checked = !checked
          }

          Item { Layout.fillWidth: true }

          TextButton {
            label: "Cancel"
            onClicked: popup.pskNetwork = null
          }

          TextButton {
            label: "Connect"
            primary: true
            onClicked: popup.submitPsk(pskInput.text)
          }
        }
      }

      Divider {}

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 30
        radius: Theme.radiusMedium
        color: settingsArea.containsMouse ? Theme.surfaceHover : "transparent"

        Accessible.role: Accessible.Button
        Accessible.name: "Network settings"

        Text {
          anchors.left: parent.left
          anchors.leftMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          text: "Network Settings…"
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
            Quickshell.execDetached(["nm-connection-editor"]);
            popup.visible = false;
          }
        }
      }
    }
  }
}
