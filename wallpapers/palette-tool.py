import colorsys
import json
import sys

CANON_SLOTS = ["base08", "base09", "base0A", "base0B", "base0C", "base0D", "base0E", "base0F"]
SHELL_SLOTS = ["base00", "base01", "base02", "base03", "base04", "base05", "base06", "base07"]
DARK_VALUE_FLOOR = 0.55
LIGHT_MIN_CONTRAST = 4.5
ACCENT_HUE_SPREAD = 40
ACCENT_MIN_CHROMA = 40
ACCENT_MIN_LEVEL = 55


def rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def hsv(value):
    r, g, b = [c / 255 for c in rgb(value)]
    return colorsys.rgb_to_hsv(r, g, b)


def to_hex(h, s, v):
    r, g, b = colorsys.hsv_to_rgb(h % 1.0, s, v)
    return "%02X%02X%02X" % (round(r * 255), round(g * 255), round(b * 255))


def luminance(value):
    r, g, b = [c / 255 for c in rgb(value)]

    def channel(c):
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)


def contrast(a, b):
    la, lb = luminance(a), luminance(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def chroma(value):
    r, g, b = rgb(value)
    return max(r, g, b) - min(r, g, b)


def hue_degrees(value):
    return hsv(value)[0] * 360


def hue_distance(a, b):
    d = abs(a - b) % 360
    return min(d, 360 - d)


def mix(a, b, t):
    ra, ga, ba = rgb(a)
    rb, gb, bb = rgb(b)
    return "%02X%02X%02X" % (
        round(ra + (rb - ra) * t),
        round(ga + (gb - ga) * t),
        round(ba + (bb - ba) * t),
    )


def brighten_to_floor(value):
    h, s, v = hsv(value)
    return to_hex(h, s, max(v, DARK_VALUE_FLOOR))


def darken_to_contrast(value, background, target=LIGHT_MIN_CONTRAST):
    if contrast(value, background) >= target:
        return value.lstrip("#").upper()
    h, s, v = hsv(value)
    lo, hi = 0.0, v
    for _ in range(40):
        mid = (lo + hi) / 2
        if contrast(to_hex(h, s, mid), background) >= target:
            lo = mid
        else:
            hi = mid
    candidate = to_hex(h, s, lo)
    if contrast(candidate, background) < target:
        candidate = to_hex(h, s, 0.0)
    return candidate


def clamp(value, mode, background):
    if mode == "light":
        return darken_to_contrast(value, background)
    return brighten_to_floor(value)


def pick_accents(candidates, mode, background):
    pool = [c.lstrip("#") for c in candidates if c]
    vivid = [c for c in pool if chroma(c) >= ACCENT_MIN_CHROMA and max(rgb(c)) >= ACCENT_MIN_LEVEL]
    vivid.sort(key=lambda c: -chroma(c))
    picks = []
    for c in vivid:
        if all(hue_distance(hue_degrees(c), hue_degrees(p)) >= ACCENT_HUE_SPREAD for p in picks):
            picks.append(c)
        if len(picks) == 3:
            break
    for c in vivid:
        if len(picks) >= 3:
            break
        if c not in picks:
            picks.append(c)
    if picks:
        h, s, v = hsv("#" + picks[0])
        s = max(s, 0.55)
        v = min(max(v, 0.55), 0.92)
        while len(picks) < 3:
            picks.append(to_hex(h + (1.0 / 3) * len(picks), s, v))
    else:
        picks = ["888888", "888888", "888888"]
    return [clamp(c, mode, background) for c in picks[:3]]


SURFACE_STEPS = {"base01": 0.07, "base02": 0.18, "base03": 0.32}


def derive_surfaces(palette, mode):
    background = palette["base00"]
    foreground = palette["base05"]
    ramp = [palette[slot] for slot in ["base00", "base01", "base02", "base03"]]
    collapsed = len({value.upper() for value in ramp}) < len(ramp)
    monotonic = all(
        abs(luminance(ramp[i + 1]) - luminance(background))
        > abs(luminance(ramp[i]) - luminance(background))
        for i in range(len(ramp) - 1)
    )
    if collapsed or not monotonic:
        for slot, step in SURFACE_STEPS.items():
            palette[slot] = mix(background, foreground, step)
    if palette["base04"].upper() == palette["base05"].upper():
        palette["base04"] = mix(background, foreground, 0.65)
    extreme = "000000" if mode == "light" else "FFFFFF"
    if palette["base06"].upper() == foreground.upper():
        palette["base06"] = mix(foreground, extreme, 0.3)
    if palette["base07"].upper() in (foreground.upper(), palette["base06"].upper()):
        palette["base07"] = mix(foreground, extreme, 0.6)
    return palette


def strip(palette):
    return {k: v.lstrip("#").upper() for k, v in palette.items()}


def build(mode, shell_path, ansi_path, accents_path):
    ansi = strip(json.load(open(ansi_path)))
    if mode == "light":
        shell = strip(json.load(open(shell_path)))
        palette = {slot: shell[slot] for slot in SHELL_SLOTS}
        palette = derive_surfaces(palette, mode)
        background = palette["base00"]
        for slot in CANON_SLOTS:
            palette[slot] = darken_to_contrast(ansi[slot], background)
    else:
        palette = dict(ansi)
        palette = derive_surfaces(palette, mode)
        background = palette["base00"]
    accents = pick_accents(json.load(open(accents_path)), mode, background)
    palette["mode"] = mode
    palette["accent"], palette["accent2"], palette["accent3"] = accents
    return palette


if __name__ == "__main__":
    mode, shell_path, ansi_path, accents_path, out_path = sys.argv[1:6]
    result = build(mode, shell_path, ansi_path, accents_path)
    with open(out_path, "w") as handle:
        json.dump(result, handle, indent=2)
        handle.write("\n")
    print(
        "%s (%s) accents #%s / #%s / #%s"
        % (out_path, mode, result["accent"], result["accent2"], result["accent3"])
    )
