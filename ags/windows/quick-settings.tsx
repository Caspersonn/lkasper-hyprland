import AstalNetwork from "gi://AstalNetwork"
import AstalBattery from "gi://AstalBattery"
import { createBinding, With } from "ags"
import QuickSettingsPanel from "./quick-settings-panel"

export default function QuickSettings() {
  //const network = AstalNetwork.get_default()
  //const wifi = createBinding(network, "wifi")
  //const battery = AstalBattery.get_default()

  //const percent = createBinding(battery, "percentage")(
  //  (p) => `${Math.floor(p * 100)}%`,
  //)

  return (
    <menubutton class="QuickSettings separator">
      <popover>
        <QuickSettingsPanel />
      </popover>
    </menubutton>
  )
}
