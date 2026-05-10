import QuickSettingsPanel from "./quick-settings-panel"

export default function QuickSettings() {
  return (
    <menubutton class="QuickSettings separator">
      <popover>
        <QuickSettingsPanel />
      </popover>
    </menubutton>
  )
}
