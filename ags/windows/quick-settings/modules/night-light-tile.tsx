import { Tile } from "../widgets/tile"
import { tilesPages } from "../tiles"
import { NightLightPage } from "./night-light-page"
import { exec } from "ags/process"
import { createState } from "ags"
import GLib from "gi://GLib"

// Night light state (managed via hyprsunset CLI)
const [isActive, setIsActive] = createState(false)
const [temperature, setTemperature] = createState(4500)

// Check if hyprsunset is available
function isInstalled(): boolean {
    try {
        exec("which hyprsunset")
        return true
    } catch {
        return false
    }
}

const available = isInstalled()

export function getTemperature() { return temperature() }
export function setNightLightTemperature(temp: number) {
    setTemperature(temp)
    if (isActive()) {
        try { exec(`pkill hyprsunset`) } catch { }
        exec(`hyprsunset -t ${temp}`)
    }
}

export function enableNightLight() {
    setIsActive(true)
    exec(`hyprsunset -t ${temperature()}`)
}

export function disableNightLight() {
    setIsActive(false)
    try { exec("pkill hyprsunset") } catch { }
}

export function NightLightTile(): Tile {
    if (!available) {
        return <Tile title="Night Light" icon="weather-clear-night-symbolic"
            visible={false} /> as Tile
    }

    return <Tile
        hasArrow
        title="Night Light"
        icon="weather-clear-night-symbolic"
        state={isActive}
        description={isActive.as((active: boolean) =>
            active ? `${temperature()}K` : "Disabled"
        )}
        onEnabled={() => enableNightLight()}
        onDisabled={() => disableNightLight()}
        onClicked={() => tilesPages?.toggle(NightLightPage)}
    /> as Tile
}
