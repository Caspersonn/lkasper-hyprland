import AstalHyprland from "gi://AstalHyprland"
import { createBinding, For } from "ags"

export default function Workspaces() {
    const hypr = AstalHyprland.get_default()

    const workspaces = createBinding(hypr, "workspaces").as(wss =>
        wss
            .filter(ws => ws.id > 0)
            .sort((a, b) => a.id - b.id)
    )

    return <box class="workspaces">
        <For each={workspaces}>
            {ws => (
                <button
                    class={createBinding(hypr, "focusedWorkspace").as(fw =>
                        `workspace-dot ${fw.id === ws.id ? "active" : "occupied"}`
                    )}
                    onClicked={() => ws.focus()}
                />
            )}
        </For>
    </box>
}
