import quicksettingsPanel from "./quick-settings-panel"

export default function quicksettings() {
  return (
    <menubutton class="quicksettings separator">
      <popover>
        <quicksettingsPanel />
      </popover>
    </menubutton>
  )
}
