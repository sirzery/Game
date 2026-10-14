"""Dialogue portraits (80x80 pixel busts, shown large in the Persona-style UI)."""
from __future__ import annotations

from typing import Dict

from pixel import MatSprite, ramp

PW, PH = 80, 80

LINE = ramp("#0e0a14", "#1a1220", "#2a2030")
WHITE = ramp("#c8c4d4", "#f6f2fa", "#ffffff")
MOUTH = ramp("#4a1820", "#7a2c36", "#a84a54")
TEETH = ramp("#c8c0c0", "#f0eaea", "#ffffff")


def _face_shading(s: MatSprite, skin: int, cx: int, cy: int, rx: float, ry: float) -> None:
    """Explicit cel shading for faces: shadow on the right cheek and jaw."""
    for y in range(s.h):
        for x in range(s.w):
            if int(s.mat[y, x]) != skin or s.tone[y, x] != -1:
                continue
            dx = (x - cx) / rx
            dy = (y - cy) / ry
            if dx > 0.45 + dy * -0.15 or dy > 0.78:
                s.tone[y, x] = 0
            elif dx < -0.55 and dy < 0.2:
                s.tone[y, x] = 2
            else:
                s.tone[y, x] = 1


def _eye(s: MatSprite, x: int, y: int, iris: int, expr: str, left: bool) -> None:
    line = s.m("line", LINE, flat=True)
    white = s.m("white", WHITE, flat=True)
    if expr == "closed":
        s.hline(x, x + 6, y + 3, line)
        s.px(x + (0 if left else 6), y + 2, line)
        return
    if expr == "sad":
        y += 1
    h = 6 if expr != "surprised" else 7
    # sclera
    s.rect(x, y + 1, x + 6, y + h - 1, white)
    # iris
    ix = x + (2 if left else 1)
    s.rect(ix, y + 1, ix + 3, y + h - 1, iris)
    for yy in range(y + 1, y + h):
        s.px(ix, yy, iris, 0)
    s.rect(ix + 1, y + 2, ix + 2, y + h - 2, line)
    s.px(ix + 2, y + 2, white, 2)
    s.px(ix + 1, y + h - 2, iris, 2)
    # lash line (thick top)
    s.hline(x - 1, x + 7, y, line)
    if expr in ("angry", "smirk", "tired"):
        s.hline(x, x + 6, y + 1, line)
    if left:
        s.px(x - 1, y + 1, line)
    else:
        s.px(x + 7, y + 1, line)
    s.hline(x + 1, x + 5, y + h, line, 0)


def _brows(s: MatSprite, cx: int, y: int, hair: int, expr: str) -> None:
    lx, rx = cx - 14, cx + 7
    if expr == "angry":
        s.line(lx, y - 1, lx + 7, y + 2, hair, width=1)
        s.line(lx, y - 2, lx + 6, y + 1, hair, width=1)
        s.line(rx, y + 2, rx + 7, y - 1, hair, width=1)
        s.line(rx + 1, y + 1, rx + 7, y - 2, hair, width=1)
    elif expr in ("sad", "pain"):
        s.line(lx, y + 1, lx + 7, y - 2, hair)
        s.line(rx, y - 2, rx + 7, y + 1, hair)
    elif expr == "surprised":
        s.hline(lx, lx + 6, y - 3, hair)
        s.hline(rx + 1, rx + 7, y - 3, hair)
    elif expr == "smirk":
        s.hline(lx, lx + 6, y, hair)
        s.line(rx, y - 1, rx + 7, y - 3, hair)
    else:
        s.hline(lx, lx + 6, y - 1, hair)
        s.hline(rx + 1, rx + 7, y - 1, hair)


def _mouth(s: MatSprite, cx: int, y: int, expr: str) -> None:
    m = s.m("mouth", MOUTH, flat=True)
    line = s.m("line", LINE, flat=True)
    if expr in ("surprised", "shout"):
        s.ellipse(cx, y + 1, 2.5, 2.5, m)
        s.hline(cx - 2, cx + 1, y - 1, line)
    elif expr == "angry":
        s.hline(cx - 3, cx + 3, y, line)
        s.px(cx - 4, y + 1, line)
        s.px(cx + 3, y + 1, line)
    elif expr == "smirk" or expr == "smile":
        s.hline(cx - 2, cx + 2, y, line)
        s.px(cx + 3, y - 1, line)
        if expr == "smile":
            s.px(cx - 3, y - 1, line)
    elif expr in ("sad", "pain"):
        s.hline(cx - 2, cx + 2, y, line)
        s.px(cx - 3, y + 1, line)
        s.px(cx + 3, y + 1, line)
        if expr == "pain":
            s.rect(cx - 2, y + 1, cx + 2, y + 1, s.m("teeth", TEETH, flat=True))
    else:
        s.hline(cx - 2, cx + 1, y, line)


def bust(spec: Dict, expr: str = "neutral") -> MatSprite:
    s = MatSprite(PW, PH)
    cx, cy = 40, 36
    skin = s.m("skin", spec["skin"])
    cloth = s.m("cloth", spec["cloth"])
    trim = s.m("trim", spec.get("trim", spec["cloth"]))
    hair = s.m("hair", spec["hair"]) if "hair" in spec else None
    iris = s.m("iris", spec.get("iris", ramp("#1a2a4a", "#3a5a8a", "#7aa0d0")), flat=True)

    # long hair behind the shoulders
    if hair and spec.get("hair_style") in ("long", "silver_long", "braid"):
        s.poly([(cx - 20, cy - 8), (cx + 20, cy - 8), (cx + 23, 78), (cx - 23, 78)], hair)
    # shoulders / clothing
    s.poly([(cx - 9, 56), (cx + 9, 56), (cx + 34, 70), (cx + 38, 79), (cx - 38, 79), (cx - 34, 70)], cloth)
    if spec.get("collar") == "scholar":
        sash = s.m("sash", spec.get("sash", ramp("#1c2240", "#2e3a6a", "#4a5c9a")))
        s.poly([(cx - 30, 70), (cx - 22, 66), (cx + 18, 79), (cx + 6, 79)], sash)
        iron = s.m("iron", ramp("#24232c", "#4e505c", "#8a8c9c"))
        s.rect(cx - 36, 74, cx - 28, 79, iron)
    elif spec.get("collar") == "armor":
        s.poly([(cx - 36, 68), (cx - 18, 58), (cx - 10, 62), (cx - 24, 76)], trim)
        s.poly([(cx + 36, 68), (cx + 18, 58), (cx + 10, 62), (cx + 24, 76)], trim)
        s.poly([(cx - 9, 58), (cx + 9, 58), (cx + 6, 70), (cx - 6, 70)], trim)
    elif spec.get("collar") == "robe":
        s.poly([(cx - 12, 56), (cx, 74), (cx + 12, 56), (cx + 16, 58), (cx, 79), (cx - 16, 58)], trim)
    elif spec.get("collar") == "dress":
        s.poly([(cx - 10, 58), (cx + 10, 58), (cx + 6, 66), (cx - 6, 66)], skin)
        s.hline(cx - 12, cx + 12, 58, trim)
        s.hline(cx - 12, cx + 12, 59, trim)
    elif spec.get("collar") == "hunter":
        s.poly([(cx - 16, 52), (cx + 16, 52), (cx + 20, 64), (cx - 20, 64)], trim)
    # neck
    if spec.get("collar") != "hunter":
        s.rect(cx - 6, 50, cx + 5, 59, skin, 0)
        s.rect(cx - 6, 50, cx - 2, 57, skin, 1)
    # head
    s.ellipse(cx, cy, 16, 18, skin)
    # pointed chin
    s.poly([(cx - 12, cy + 8), (cx + 12, cy + 8), (cx + 2, cy + 19), (cx - 2, cy + 19)], skin)
    # ear
    s.ellipse(cx - 16, cy + 2, 2.5, 4, skin)
    s.ellipse(cx + 16, cy + 2, 2.5, 4, skin, 0)
    _face_shading(s, skin, cx, cy, 16, 18)

    if hair:
        _hair(s, hair, skin, cx, cy, spec.get("hair_style", "messy"))
    masked = spec.get("masked")
    if masked:
        mask = s.m("mask", spec["mask"])
        s.ellipse(cx, cy + 2, 15, 17, mask)
        s.poly([(cx - 11, cy + 8), (cx + 11, cy + 8), (cx + 2, cy + 19), (cx - 2, cy + 19)], mask)
        glow = s.m("maskeye", spec.get("mask_eye", ramp("#401010", "#ff4030", "#ffb090")), flat=True,
                   emissive=True)
        line = s.m("line", LINE, flat=True)
        for ex in (cx - 12, cx + 4):
            s.poly([(ex, cy + 1), (ex + 8, cy - 1), (ex + 8, cy + 2), (ex, cy + 3)], line)
            s.hline(ex + 2, ex + 6, cy + 1, glow)
        # engraved lines on the mask
        s.vline(cx, cy - 14, cy - 4, line)
        s.hline(cx - 3, cx + 3, cy + 12, line)
        for k in range(3):
            s.px(cx - 8 + k, cy + 8 + k, line)
            s.px(cx + 8 - k, cy + 8 + k, line)
    elif spec.get("shadowed"):
        shadow = s.m("shadow", ramp("#08060c", "#0e0a14", "#16101e"), flat=True)
        s.ellipse(cx, cy, 16, 18, shadow)
        s.poly([(cx - 12, cy + 8), (cx + 12, cy + 8), (cx + 2, cy + 19), (cx - 2, cy + 19)], shadow)
        glow = s.m("eyeglow", spec.get("glow", ramp("#0a6a7a", "#40e8ff", "#d8ffff")), flat=True,
                   emissive=True)
        s.poly([(cx - 12, cy + 2), (cx - 4, cy), (cx - 5, cy + 3)], glow)
        s.poly([(cx + 12, cy + 2), (cx + 4, cy), (cx + 5, cy + 3)], glow)
    else:
        ey = cy - 1
        _eye(s, cx - 13, ey, iris, expr, True)
        _eye(s, cx + 6, ey, iris, expr, False)
        brow_col = s.m("brow", spec.get("brow", spec.get("hair", LINE)), flat=True)
        _brows(s, cx, ey - 3, brow_col, expr)
        # nose
        s.px(cx + 1, cy + 7, skin, 0)
        s.px(cx + 1, cy + 8, skin, 0)
        _mouth(s, cx, cy + 13, expr)
        if spec.get("freckles"):
            fr = s.m("freckle", ramp("#8a4a3a", "#b06a50", "#c88468"), flat=True)
            for (fx, fy) in ((-10, 9), (-8, 10), (-11, 11), (8, 9), (10, 10), (7, 11)):
                s.px(cx + fx, cy + fy, fr)
        if spec.get("scar"):
            sc = s.m("scar", ramp("#8a4a40", "#b0645a", "#d08070"), flat=True)
            s.line(cx + 9, cy + 6, cx + 12, cy + 11, sc)
        if expr in ("angry", "pain", "surprised") and spec.get("sweat"):
            sw = s.m("sweat", ramp("#5a8ab0", "#a0d0f0", "#ffffff"), flat=True)
            s.rect(cx + 14, cy - 8, cx + 15, cy - 5, sw)
        blush = spec.get("blush")
        if blush or expr == "flustered":
            bl = s.m("blush", ramp("#c06060", "#e08080", "#f0a0a0"), flat=True)
            s.hline(cx - 12, cx - 8, cy + 8, bl)
            s.hline(cx + 7, cx + 11, cy + 8, bl)

    hat = spec.get("hat")
    if hat:
        _hat(s, spec, cx, cy, hat)
    if spec.get("hood"):
        hood = s.m("hood", spec["hood"])
        s.poly([(cx - 20, 79), (cx - 22, cy), (cx - 12, cy - 22), (cx, cy - 26), (cx + 12, cy - 22),
                (cx + 22, cy), (cx + 20, 79), (cx + 14, 79), (cx + 16, cy + 2), (cx + 10, cy - 14),
                (cx, cy - 17), (cx - 10, cy - 14), (cx - 16, cy + 2), (cx - 14, 79)], hood)
        if spec.get("scarf"):
            sc = s.m("scarf", spec["scarf"])
            s.poly([(cx - 16, cy + 8), (cx + 16, cy + 8), (cx + 18, cy + 24), (cx - 18, cy + 24)], sc)
            for x in range(cx - 14, cx + 14, 4):
                s.vline(x, cy + 10, cy + 22, sc, 0)
    if spec.get("horns"):
        horn = s.m("horn", ramp("#6a5e50", "#b8ac98", "#ece2cc"))
        s.poly([(cx - 12, cy - 12), (cx - 8, cy - 16), (cx - 24, cy - 34), (cx - 30, cy - 34), (cx - 20, cy - 24)],
               horn)
        s.poly([(cx + 12, cy - 12), (cx + 8, cy - 16), (cx + 24, cy - 34), (cx + 30, cy - 34), (cx + 20, cy - 24)],
               horn)
    return s


def _carve_face(s: MatSprite, hair: int, skin: int, cx: int, cy: int, top: int) -> None:
    for y in range(cy + top, cy + 20):
        for x in range(cx - 15, cx + 16):
            dx = (x + 0.5 - cx) / 15.5
            dy = (y + 0.5 - cy) / 18.5
            if dx * dx + dy * dy <= 1.0 and int(s.mat[y, x]) == hair:
                tone = 0 if dx > 0.45 else (2 if dx < -0.55 and dy < 0.2 else 1)
                if y <= cy + top + 1:
                    tone = 0  # hair casts a thin shadow on the forehead
                s.px(x, y, skin, tone)


def _hair(s: MatSprite, hair: int, skin: int, cx: int, cy: int, style: str) -> None:
    if style == "messy":
        s.ellipse(cx, cy - 8, 19, 14, hair)
        _carve_face(s, hair, skin, cx, cy, -8)
        # spiky crown
        for (x, y) in ((-14, -20), (-8, -24), (-1, -26), (6, -24), (12, -21), (17, -15)):
            s.poly([(cx + x - 4, cy + y + 6), (cx + x + 4, cy + y + 6), (cx + x + 1, cy + y)], hair)
        # bangs falling over the forehead in jagged locks
        locks = [(-17, 12), (-13, 5), (-9, 3), (-4, 4), (0, 2), (4, 4), (9, 3), (13, 5), (17, 11)]
        for (x, d) in locks:
            s.poly([(cx + x - 4, cy - 8), (cx + x + 3, cy - 8), (cx + x, cy - 8 + d)], hair)
        s.rect(cx - 19, cy - 8, cx - 15, cy + 6, hair)
        s.rect(cx + 15, cy - 8, cx + 19, cy + 4, hair)
    elif style in ("long", "silver_long"):
        s.ellipse(cx, cy - 8, 19, 14, hair)
        _carve_face(s, hair, skin, cx, cy, -8)
        s.poly([(cx - 19, cy - 8), (cx + 4, cy - 8), (cx - 8, cy - 5), (cx - 17, cy - 1)], hair)
        s.poly([(cx + 4, cy - 8), (cx + 19, cy - 8), (cx + 18, cy - 2), (cx + 12, cy - 5)], hair)
        s.rect(cx - 21, cy - 6, cx - 16, cy + 30, hair)
        s.rect(cx + 16, cy - 6, cx + 21, cy + 30, hair)
    elif style == "braid":
        s.ellipse(cx, cy - 8, 18, 13, hair)
        _carve_face(s, hair, skin, cx, cy, -8)
        s.poly([(cx - 18, cy - 8), (cx + 6, cy - 8), (cx - 6, cy - 5), (cx - 17, cy - 1)], hair)
        s.poly([(cx + 6, cy - 8), (cx + 18, cy - 8), (cx + 17, cy - 2), (cx + 12, cy - 5)], hair)
        s.rect(cx - 19, cy - 6, cx - 15, cy + 8, hair)
        # braid over the shoulder
        for i in range(10):
            yy = cy + 6 + i * 3
            xx = cx + 17 + (1 if i % 2 else -1)
            s.ellipse(xx, yy, 3.5, 2.2, hair)
        rib = s.m("ribbon", ramp("#6a1a24", "#b03040", "#e06070"))
        s.rect(cx + 14, cy + 36, cx + 20, cy + 38, rib)
    elif style == "short":
        s.ellipse(cx, cy - 9, 18, 12, hair)
        _carve_face(s, hair, skin, cx, cy, -8)
        s.rect(cx - 17, cy - 9, cx + 17, cy - 6, hair)


def _hat(s: MatSprite, spec: Dict, cx: int, cy: int, hat: str) -> None:
    if hat == "mitre":
        hc = s.m("hat_col", spec["hat_col"])
        trim = s.m("trim", spec.get("trim", spec["hat_col"]))
        s.poly([(cx - 17, cy - 6), (cx - 15, cy - 26), (cx, cy - 40), (cx + 15, cy - 26), (cx + 17, cy - 6)], hc)
        s.rect(cx - 17, cy - 9, cx + 17, cy - 6, trim)
        s.rect(cx - 1, cy - 38, cx + 1, cy - 10, trim)
        sig = s.m("sigil", ramp("#a06010", "#ffcc40", "#fff0a0"), flat=True, emissive=True)
        for y in range(cy - 28, cy - 17):
            for x in range(cx - 6, cx + 7):
                d = ((x - cx) ** 2 + (y - (cy - 22.5)) ** 2) ** 0.5
                if 4 < d < 5.5 or d < 1.5:
                    s.px(x, y, sig)
        # cloth hanging at the sides
        s.rect(cx - 19, cy - 6, cx - 15, cy + 22, hc)
        s.rect(cx + 15, cy - 6, cx + 19, cy + 22, hc)
    elif hat == "halo":
        halo = s.m("halo", ramp("#c09030", "#ffe890", "#fffff0"), flat=True, emissive=True)
        for x in range(cx - 18, cx + 19):
            dy = int(round(((x - cx) / 18.0) ** 2 * 3))
            s.px(x, cy - 28 + dy, halo)
            s.px(x, cy - 27 + dy, halo)
    elif hat == "helm":
        hc = s.m("hat_col", spec["hat_col"])
        trim = s.m("trim_h", spec.get("trim", spec["hat_col"]))
        s.ellipse(cx, cy - 2, 19, 21, hc)
        visor = s.m("visor", ramp("#08060a", "#14101a", "#241c2c"), flat=True)
        s.rect(cx - 15, cy, cx + 15, cy + 3, visor)
        s.vline(cx, cy - 22, cy + 18, trim)
        eyeg = s.m("helmeye", ramp("#401010", "#ff5a3a", "#ffc0a0"), flat=True, emissive=True)
        s.hline(cx - 10, cx - 6, cy + 1, eyeg)
        s.hline(cx + 6, cx + 10, cy + 1, eyeg)
        for y in range(cy + 6, cy + 16, 3):
            s.hline(cx - 8, cx + 8, y, visor)
