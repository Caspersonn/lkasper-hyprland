import QuickSettingsPanel from "./quick-settings-panel"

export default function QuickSettings() {
  return (
    <menubutton class="quicksettings separator">
      <popover>
        <QuickSettingsPanel />
      </popover>
    </menubutton>
  )
}
