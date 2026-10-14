"""Parametric chibi humanoid builder (32x48 frames) for DOSIER.

A character is described by a spec dictionary (colours + style keys). The
builder draws flat material regions for a given direction / pose / frame and
pixel.MatSprite takes care of cel shading and outlines.
"""
from __future__ import annotations

from typing import Dict, Optional

from pixel import MatSprite, ramp

FW, FH = 32, 48

EYE_DARK = ramp("#120c18", "#1e1428", "#2c2038")
EYE_WHITE = ramp("#c8c4d4", "#f4f0f8", "#ffffff")
MOUTH = ramp("#5a2028", "#7a3038", "#9a4048")
IRON = ramp("#24232c", "#4e505c", "#8a8c9c")


def _mat(s: MatSprite, spec: Dict, key: str, flat: bool = False, emissive: bool = False) -> int:
    return s.m(key, spec[key], flat=flat, emissive=emissive)


# ---------------------------------------------------------------------------
# Heads
# ---------------------------------------------------------------------------
def head_front(s: MatSprite, spec: Dict, cx: int, cy: int, expr: str = "neutral",
               look_up: bool = False) -> None:
    skin = _mat(s, spec, "skin")
    s.ellipse(cx, cy, 7, 7, skin)
    # cheeks / jaw slightly narrower at the bottom
    s.erase(cx - 7, cy + 4)
    s.erase(cx + 6, cy + 4)
    hat = spec.get("hat")
    ey = cy + (-1 if look_up else 0)
    if spec.get("coif"):
        coif = s.m("coif", spec["coif"])
        s.ellipse(cx, cy, 8, 8, coif)
        s.ellipse(cx, cy + 1, 6, 6.5, skin)
    hair_front(s, spec, cx, cy)
    if not spec.get("masked"):
        eye = s.m("eye", spec.get("eye", EYE_DARK), flat=True)
        white = s.m("eyew", EYE_WHITE, flat=True)
        if expr == "closed":
            s.hline(cx - 5, cx - 3, ey + 1, eye)
            s.hline(cx + 2, cx + 4, ey + 1, eye)
        else:
            for ex in (cx - 4, cx + 2):
                s.rect(ex, ey, ex + 1, ey + 2, eye)
                s.px(ex + (1 if ex < cx else 0), ey, white, 1)
            # soft blush under the eyes
            blush = s.m("blush", spec.get("blush", (spec["skin"][1],) * 3), flat=True)
            s.px(cx - 5, ey + 3, blush, 0)
            s.px(cx + 4, ey + 3, blush, 0)
            if expr == "angry":
                s.hline(cx - 5, cx - 3, ey - 2, eye)
                s.px(cx - 3, ey - 1, eye)
                s.hline(cx + 2, cx + 4, ey - 2, eye)
                s.px(cx + 2, ey - 1, eye)
        mouth = s.m("mouth", MOUTH, flat=True)
        if expr in ("shout", "pain") or look_up:
            s.rect(cx - 1, cy + 4, cx, cy + 5, mouth)
        elif expr == "smirk":
            s.hline(cx - 1, cx + 1, cy + 4, mouth)
            s.px(cx + 1, cy + 3, mouth)
        else:
            s.hline(cx - 1, cx, cy + 4, mouth)
    else:
        mask = s.m("mask", spec["mask"])
        s.ellipse(cx, cy + 1, 6, 6, mask)
        eyeg = s.m("maskeye", spec.get("mask_eye", ramp("#401010", "#ff4030", "#ffb090")), flat=True,
                   emissive=True)
        s.hline(cx - 4, cx - 3, cy + 1, eyeg)
        s.hline(cx + 2, cx + 3, cy + 1, eyeg)
    if hat:
        hat_front(s, spec, cx, cy)


def hair_front(s: MatSprite, spec: Dict, cx: int, cy: int) -> None:
    style = spec.get("hair_style", "messy")
    if style == "none" or "hair" not in spec:
        return
    hair = _mat(s, spec, "hair")
    top = cy - 7
    if style in ("messy", "short", "long", "braid", "silver_long"):
        s.ellipse(cx, cy - 2, 8, 6, hair)
        # clear the face again below the fringe line
        for y in range(cy - 2, cy + 8):
            for x in range(cx - 6, cx + 6):
                if s.mat[y, x] == hair:
                    s.px(x, y, s.m("skin", spec["skin"]))
        # fringe
        if style == "messy":
            # jagged fringe that stops above the eyes (eyes sit on rows cy..cy+1)
            for x, d in ((cx - 6, 3), (cx - 5, 2), (cx - 4, 0), (cx - 3, 1), (cx - 2, 0), (cx - 1, 1),
                         (cx, 0), (cx + 1, 1), (cx + 2, 0), (cx + 3, 1), (cx + 4, 2), (cx + 5, 3)):
                s.vline(x, cy - 2, cy - 2 + d, hair)
            # spikes on top
            s.px(cx - 3, top - 1, hair)
            s.px(cx + 1, top - 2, hair)
            s.px(cx + 2, top - 1, hair)
            s.px(cx + 5, top, hair)
        elif style == "short":
            for x in range(cx - 6, cx + 6):
                s.px(x, cy - 1, hair)
            s.vline(cx - 6, cy, cy + 1, hair)
            s.vline(cx + 5, cy, cy + 1, hair)
        else:
            # side-swept fringe for long styles
            for x in range(cx - 6, cx + 2):
                s.px(x, cy - 1, hair)
            for x in range(cx - 6, cx - 2):
                s.px(x, cy, hair)
        # sides
        side_len = {"messy": 4, "short": 3, "long": 12, "braid": 6, "silver_long": 16}[style]
        for x in (cx - 8, cx - 7, cx + 6, cx + 7):
            s.vline(x, cy - 2, cy - 2 + side_len, hair)
        if style in ("long", "silver_long"):
            s.vline(cx - 9, cy + 2, cy - 2 + side_len, hair)
            s.vline(cx + 8, cy + 2, cy - 2 + side_len, hair)
        if style == "braid":
            for i in range(9):
                yy = cy + 4 + i
                xx = cx + 7 + (i % 2)
                s.px(xx, yy, hair)
                s.px(xx - 1, yy, hair)
            ribbon = s.m("ribbon", spec.get("ribbon", ramp("#6a1a24", "#b03040", "#e06070")), flat=True)
            s.rect(cx + 6, cy + 13, cx + 8, cy + 13, ribbon)


def hat_front(s: MatSprite, spec: Dict, cx: int, cy: int) -> None:
    hat = spec["hat"]
    hc = _mat(s, spec, "hat_col")
    if hat == "mitre":
        trim = s.m("trim", spec.get("trim", spec["hat_col"]))
        s.poly([(cx - 6, cy - 3), (cx - 5, cy - 14), (cx, cy - 19), (cx + 5, cy - 14), (cx + 6, cy - 3)], hc)
        s.hline(cx - 6, cx + 5, cy - 3, trim)
        s.hline(cx - 6, cx + 5, cy - 4, trim)
        s.vline(cx - 1, cy - 17, cy - 5, trim)
        s.vline(cx, cy - 17, cy - 5, trim)
        sig = s.m("sigil", spec.get("sigil", ramp("#a06010", "#ffcc40", "#fff0a0")), flat=True, emissive=True)
        s.rect(cx - 1, cy - 11, cx, cy - 10, sig)
    elif hat == "hood":
        s.ellipse(cx, cy - 1, 9, 9, hc)
        # carve the face opening
        for y in range(cy - 3, cy + 8):
            for x in range(cx - 6, cx + 6):
                dx = (x + 0.5 - cx) / 6.0
                dy = (y + 0.5 - (cy + 2)) / 6.5
                if dx * dx + dy * dy <= 1.0:
                    s.px(x, y, s.m("skin", spec["skin"]) if not spec.get("masked") else s.m("mask", spec["mask"]))
    elif hat == "helm":
        trim = s.m("trim", spec.get("trim", spec["hat_col"]))
        s.ellipse(cx, cy - 1, 8, 8, hc)
        # visor slit
        visor = s.m("visor", ramp("#08060a", "#14101a", "#241c2c"), flat=True)
        s.rect(cx - 6, cy, cx + 5, cy + 1, visor)
        s.vline(cx - 1, cy - 8, cy + 6, trim)
        s.vline(cx, cy - 8, cy + 6, trim)
        s.rect(cx - 7, cy + 4, cx + 6, cy + 7, hc)
        eyeg = s.m("helmeye", ramp("#401010", "#ff5a3a", "#ffc0a0"), flat=True, emissive=True)
        s.px(cx - 3, cy, eyeg)
        s.px(cx + 2, cy, eyeg)
        # plume
        if spec.get("plume"):
            pl = s.m("plume", spec["plume"])
            s.poly([(cx - 1, cy - 9), (cx + 1, cy - 9), (cx + 6, cy - 13), (cx + 3, cy - 8)], pl)
    elif hat == "halo":
        halo = s.m("halo", ramp("#c09030", "#ffe890", "#fffff0"), flat=True, emissive=True)
        for x in range(cx - 7, cx + 7):
            s.px(x, cy - 11, halo)
        s.px(cx - 8, cy - 10, halo)
        s.px(cx + 7, cy - 10, halo)


def head_back(s: MatSprite, spec: Dict, cx: int, cy: int) -> None:
    skin = _mat(s, spec, "skin")
    s.ellipse(cx, cy, 7, 7, skin)
    if spec.get("coif"):
        coif = s.m("coif", spec["coif"])
        s.ellipse(cx, cy, 8, 8, coif)
    hat = spec.get("hat")
    style = spec.get("hair_style", "messy")
    if "hair" in spec and style != "none":
        hair = _mat(s, spec, "hair")
        s.ellipse(cx, cy - 1, 8, 7.5, hair)
        if style == "messy":
            s.px(cx - 3, cy - 9, hair)
            s.px(cx + 2, cy - 9, hair)
            s.px(cx + 1, cy - 10, hair)
            for x in range(cx - 5, cx + 5, 2):
                s.px(x, cy + 7, hair)
        if style in ("long", "silver_long"):
            ln = 10 if style == "long" else 14
            s.rect(cx - 7, cy + 2, cx + 6, cy + 2 + ln, hair)
        if style == "braid":
            for i in range(10):
                s.px(cx - 1 + (i % 2), cy + 6 + i, hair)
                s.px(cx + (i % 2), cy + 6 + i, hair)
    if hat == "mitre" or hat == "helm" or hat == "hood":
        hat_front(s, spec, cx, cy)
        if hat == "hood":
            hc = _mat(s, spec, "hat_col")
            s.ellipse(cx, cy, 8, 8, hc)
        if hat == "helm":
            hc = _mat(s, spec, "hat_col")
            s.ellipse(cx, cy - 1, 8, 8, hc)
            s.rect(cx - 7, cy + 4, cx + 6, cy + 7, hc)
    elif hat == "halo":
        hat_front(s, spec, cx, cy)


def head_side(s: MatSprite, spec: Dict, cx: int, cy: int, expr: str = "neutral") -> None:
    """Facing right."""
    skin = _mat(s, spec, "skin")
    s.ellipse(cx + 1, cy, 6.5, 7, skin)
    s.px(cx + 7, cy + 1, skin)  # nose
    hat = spec.get("hat")
    if spec.get("coif"):
        coif = s.m("coif", spec["coif"])
        s.ellipse(cx, cy, 8, 8, coif)
        s.ellipse(cx + 3, cy + 1, 4.5, 6.5, skin)
    style = spec.get("hair_style", "messy")
    if "hair" in spec and style != "none":
        hair = _mat(s, spec, "hair")
        s.ellipse(cx, cy - 2, 7.5, 6, hair)
        # back of the head
        s.rect(cx - 7, cy - 2, cx - 1, cy + 3, hair)
        for y in range(cy - 1, cy + 8):
            for x in range(cx + 1, cx + 9):
                if s.mat[y, x] == hair:
                    s.px(x, y, skin)
        s.px(cx + 1, cy - 1, hair)
        s.px(cx + 2, cy - 1, hair)
        s.px(cx + 6, cy - 1, hair)
        s.vline(cx, cy - 1, cy + 3, hair)
        if style == "messy":
            s.px(cx - 4, cy - 9, hair)
            s.px(cx - 1, cy - 10, hair)
            s.px(cx + 3, cy - 9, hair)
            s.px(cx - 8, cy - 1, hair)
            s.px(cx - 8, cy + 2, hair)
        if style in ("long", "silver_long"):
            ln = 10 if style == "long" else 14
            s.rect(cx - 6, cy + 2, cx - 1, cy + 2 + ln, hair)
        if style == "braid":
            for i in range(9):
                s.px(cx - 6 + (i % 2), cy + 3 + i, hair)
                s.px(cx - 5 + (i % 2), cy + 3 + i, hair)
    if not spec.get("masked"):
        eye = s.m("eye", spec.get("eye", EYE_DARK), flat=True)
        white = s.m("eyew", EYE_WHITE, flat=True)
        if expr == "closed":
            s.hline(cx + 3, cx + 5, cy + 1, eye)
        else:
            s.rect(cx + 4, cy, cx + 5, cy + 2, eye)
            s.px(cx + 5, cy, white, 1)
            if expr == "angry":
                s.hline(cx + 3, cx + 6, cy - 2, eye)
        mouth = s.m("mouth", MOUTH, flat=True)
        if expr in ("shout", "pain"):
            s.rect(cx + 5, cy + 4, cx + 6, cy + 5, mouth)
        else:
            s.px(cx + 5, cy + 4, mouth)
    else:
        mask = s.m("mask", spec["mask"])
        s.ellipse(cx + 3, cy + 1, 4.5, 6, mask)
        eyeg = s.m("maskeye", spec.get("mask_eye", ramp("#401010", "#ff4030", "#ffb090")), flat=True,
                   emissive=True)
        s.hline(cx + 4, cx + 6, cy + 1, eyeg)
    if hat:
        hc = _mat(s, spec, "hat_col")
        if hat == "mitre":
            trim = s.m("trim", spec.get("trim", spec["hat_col"]))
            s.poly([(cx - 5, cy - 3), (cx - 4, cy - 14), (cx + 1, cy - 19), (cx + 5, cy - 14),
                    (cx + 6, cy - 3)], hc)
            s.hline(cx - 5, cx + 5, cy - 3, trim)
            s.hline(cx - 5, cx + 5, cy - 4, trim)
        elif hat == "helm":
            trim = s.m("trim", spec.get("trim", spec["hat_col"]))
            s.ellipse(cx, cy - 1, 8, 8, hc)
            visor = s.m("visor", ramp("#08060a", "#14101a", "#241c2c"), flat=True)
            s.rect(cx + 2, cy, cx + 7, cy + 1, visor)
            eyeg = s.m("helmeye", ramp("#401010", "#ff5a3a", "#ffc0a0"), flat=True, emissive=True)
            s.px(cx + 5, cy, eyeg)
            s.rect(cx - 7, cy + 3, cx + 5, cy + 7, hc)
            s.hline(cx - 7, cx + 7, cy - 2, trim)
            if spec.get("plume"):
                pl = s.m("plume", spec["plume"])
                s.poly([(cx - 2, cy - 9), (cx, cy - 9), (cx - 8, cy - 12), (cx - 5, cy - 7)], pl)
        elif hat == "hood":
            s.ellipse(cx - 1, cy - 1, 8.5, 8.5, hc)
            for y in range(cy - 3, cy + 8):
                for x in range(cx + 2, cx + 9):
                    dx = (x + 0.5 - (cx + 5)) / 4.0
                    dy = (y + 0.5 - (cy + 2)) / 6.5
                    if dx * dx + dy * dy <= 1.0:
                        s.px(x, y, skin if not spec.get("masked") else s.m("mask", spec["mask"]))
        elif hat == "halo":
            hat_front(s, spec, cx, cy)


# ---------------------------------------------------------------------------
# Bodies
# ---------------------------------------------------------------------------
def body_front(s: MatSprite, spec: Dict, cx: int, top: int, frame: int = 0, back: bool = False,
               arms_pose: str = "down") -> None:
    style = spec.get("top_style", "tunic")
    top_m = _mat(s, spec, "top")
    skin = _mat(s, spec, "skin")
    legs = s.m("legs", spec.get("legs", spec["top"]))
    feet = s.m("feet", spec["feet"]) if spec.get("feet") else skin
    trim = s.m("trim", spec["trim"]) if spec.get("trim") else None

    # legs
    ly = top + 15
    lift_l = 2 if frame == 1 else 0
    lift_r = 2 if frame == 2 else 0
    if style not in ("robe", "dress", "long_robe"):
        s.rect(cx - 4, ly, cx - 1, ly + 6 - lift_l, legs)
        s.rect(cx, ly, cx + 3, ly + 6 - lift_r, legs)
        s.rect(cx - 5, ly + 7 - lift_l, cx - 1, ly + 8 - lift_l, feet)
        s.rect(cx, ly + 7 - lift_r, cx + 4, ly + 8 - lift_r, feet)
    else:
        s.rect(cx - 4, ly + 6 - lift_l, cx - 1, ly + 8 - lift_l, feet)
        s.rect(cx, ly + 6 - lift_r, cx + 3, ly + 8 - lift_r, feet)

    # neck
    s.rect(cx - 2, top - 2, cx + 1, top, skin)
    # torso
    if style == "tunic":
        s.poly([(cx - 6, top), (cx + 6, top), (cx + 7, top + 16), (cx - 7, top + 16)], top_m)
        # ragged hem
        for x in range(cx - 7, cx + 7, 3):
            s.px(x, top + 16, top_m)
            s.erase(x + 1, top + 16)
        belt = s.m("belt", spec.get("belt", ramp("#2a1c18", "#4a3428", "#6a4c38")))
        s.hline(cx - 6, cx + 5, top + 9, belt)
        if spec.get("sash"):
            sash = s.m("sash", spec["sash"])
            for i in range(10):
                xx = (cx - 5 + i) if not back else (cx + 4 - i)
                s.px(xx, top + i, sash)
                s.px(xx + 1, top + i, sash)
        if not back:
            s.px(cx - 1, top + 1, skin)
            s.px(cx, top + 1, skin)
            s.px(cx - 1, top + 2, skin, 0)
            # torn patch
            patch = s.m("patch", spec.get("patch", spec["top"]))
            s.rect(cx + 2, top + 4, cx + 3, top + 5, patch, 0)
    elif style in ("robe", "long_robe"):
        bottom = top + 22
        s.poly([(cx - 6, top), (cx + 6, top), (cx + 9, bottom), (cx - 9, bottom)], top_m)
        if trim and not back:
            s.vline(cx - 1, top, bottom, trim)
            s.vline(cx, top, bottom, trim)
            s.hline(cx - 9, cx + 8, bottom, trim)
            s.hline(cx - 5, cx + 4, top, trim)
        if spec.get("stole") and not back:
            st = s.m("stole", spec["stole"])
            s.rect(cx - 4, top, cx - 3, top + 14, st)
            s.rect(cx + 2, top, cx + 3, top + 14, st)
    elif style == "dress":
        bottom = top + 21
        s.poly([(cx - 5, top), (cx + 5, top), (cx + 9, bottom), (cx - 9, bottom)], top_m)
        if spec.get("apron") and not back:
            ap = s.m("apron", spec["apron"])
            s.poly([(cx - 4, top + 7), (cx + 4, top + 7), (cx + 5, bottom - 2), (cx - 5, bottom - 2)], ap)
        bodice = s.m("bodice", spec.get("bodice", spec["top"]))
        s.rect(cx - 5, top, cx + 4, top + 6, bodice)
        if not back:
            s.rect(cx - 2, top, cx + 1, top + 1, skin)
            s.px(cx - 1, top + 2, skin)
            s.px(cx, top + 2, skin)
    elif style == "armor":
        s.poly([(cx - 7, top), (cx + 7, top), (cx + 7, top + 15), (cx - 7, top + 15)], top_m)
        if trim:
            tab = s.m("tabard", spec.get("tabard", spec["trim"]))
            s.rect(cx - 4, top + 3, cx + 3, top + 17, tab)
            if not back:
                # the Synod's sigil: an open eye inside a sun ring
                sig = s.m("sigil", spec.get("sigil", ramp("#a06010", "#d8a030", "#fff0a0")), flat=True)
                s.hline(cx - 2, cx + 1, top + 6, sig)
                s.hline(cx - 2, cx + 1, top + 11, sig)
                s.vline(cx - 3, top + 7, top + 10, sig)
                s.vline(cx + 2, top + 7, top + 10, sig)
                s.rect(cx - 1, top + 8, cx, top + 9, sig)
        pauld = s.m("pauldron", spec.get("pauldron", spec["top"]))
        s.ellipse(cx - 7, top + 2, 3, 3, pauld)
        s.ellipse(cx + 7, top + 2, 3, 3, pauld)

    if spec.get("cape"):
        cp = s.m("cape", spec["cape"])
        if back:
            s.poly([(cx - 7, top), (cx + 7, top), (cx + 9, top + 22), (cx - 9, top + 22)], cp)
        else:
            s.rect(cx - 8, top + 1, cx - 7, top + 20, cp)
            s.rect(cx + 7, top + 1, cx + 8, top + 20, cp)

    # arms
    sleeve = s.m("sleeve", spec.get("sleeve", spec["top"]))
    swing_l = {0: 0, 1: 1, 2: -1}[frame]
    swing_r = -swing_l
    if arms_pose == "down":
        for side, sw in ((-1, swing_l), (1, swing_r)):
            ax = cx - 9 if side < 0 else cx + 6
            s.rect(ax, top + 1, ax + 2, top + 9 + sw, sleeve)
            s.rect(ax, top + 10 + sw, ax + 2, top + 11 + sw, skin)
            if spec.get("cuffs"):
                iron = s.m("iron", IRON)
                s.rect(ax, top + 9 + sw, ax + 2, top + 9 + sw, iron)
    elif arms_pose == "pray":
        for side in (-1, 1):
            ax = cx - 9 if side < 0 else cx + 6
            s.rect(ax, top + 1, ax + 2, top + 6, sleeve)
        s.rect(cx - 7, top + 6, cx + 6, top + 8, sleeve)
        s.rect(cx - 1, top + 5, cx, top + 7, skin)
    elif arms_pose == "raise":
        s.rect(cx - 9, top + 1, cx - 7, top + 10, sleeve)
        s.rect(cx - 9, top + 11, cx - 7, top + 12, skin)
        s.rect(cx + 6, top - 9, cx + 8, top + 2, sleeve)
        s.rect(cx + 6, top - 11, cx + 8, top - 10, skin)
    elif arms_pose == "lantern":
        s.rect(cx - 9, top + 1, cx - 7, top + 10, sleeve)
        s.rect(cx - 9, top + 11, cx - 7, top + 12, skin)
        s.rect(cx + 6, top + 1, cx + 8, top + 7, sleeve)
        s.rect(cx + 6, top + 8, cx + 8, top + 9, skin)
        frame_m = s.m("lantern_frame", ramp("#2a1c14", "#5a4028", "#8a6440"))
        glass = s.m("lantern_glass", ramp("#c06010", "#ffb040", "#fff0b0"), flat=True, emissive=True)
        s.vline(cx + 8, top + 10, top + 11, frame_m)
        s.rect(cx + 7, top + 12, cx + 10, top + 17, frame_m)
        s.rect(cx + 8, top + 13, cx + 9, top + 16, glass)

    if spec.get("cuffs"):
        iron = s.m("iron", IRON)
        if style not in ("robe", "dress", "long_robe"):
            s.hline(cx - 4, cx - 1, ly + 6 - lift_l, iron)
            s.hline(cx, cx + 3, ly + 6 - lift_r, iron)


def body_side(s: MatSprite, spec: Dict, cx: int, top: int, frame: int = 0,
              arms_pose: str = "down") -> None:
    """Facing right."""
    style = spec.get("top_style", "tunic")
    top_m = _mat(s, spec, "top")
    skin = _mat(s, spec, "skin")
    legs = s.m("legs", spec.get("legs", spec["top"]))
    feet = s.m("feet", spec["feet"]) if spec.get("feet") else skin
    trim = s.m("trim", spec["trim"]) if spec.get("trim") else None
    sleeve = s.m("sleeve", spec.get("sleeve", spec["top"]))
    ly = top + 15
    stride = {0: 0, 1: 3, 2: -3}[frame]

    if spec.get("cape"):
        cp = s.m("cape", spec["cape"])
        s.poly([(cx - 4, top), (cx - 1, top), (cx - 4, top + 21), (cx - 9, top + 21)], cp)

    # back arm (behind body)
    back_arm = s.m("sleeve_back", (spec.get("sleeve", spec["top"])[0],) * 3)
    if arms_pose == "down":
        s.rect(cx - 1 - stride // 2, top + 1, cx + 1 - stride // 2, top + 10, back_arm)
    # legs
    if style not in ("robe", "dress", "long_robe"):
        s.rect(cx - 2 + stride, ly, cx + 1 + stride, ly + 6, legs)
        s.rect(cx - 2 - stride, ly, cx + 1 - stride, ly + 6, legs, 0)
        s.rect(cx - 2 + stride, ly + 7, cx + 3 + stride, ly + 8, feet)
        s.rect(cx - 2 - stride, ly + 7, cx + 3 - stride, ly + 8, feet, 0)
        if spec.get("cuffs"):
            iron = s.m("iron", IRON)
            s.hline(cx - 2 + stride, cx + 1 + stride, ly + 6, iron)
            s.hline(cx - 2 - stride, cx + 1 - stride, ly + 6, iron)
    else:
        s.rect(cx - 2 + stride // 2, ly + 6, cx + 3 + stride // 2, ly + 8, feet)
        s.rect(cx - 2 - stride // 2, ly + 6, cx + 3 - stride // 2, ly + 8, feet, 0)
    s.rect(cx - 1, top - 2, cx + 2, top, skin)
    if style == "tunic":
        s.poly([(cx - 4, top), (cx + 4, top), (cx + 5, top + 16), (cx - 5, top + 16)], top_m)
        for x in range(cx - 5, cx + 5, 3):
            s.erase(x + 1, top + 16)
        belt = s.m("belt", spec.get("belt", ramp("#2a1c18", "#4a3428", "#6a4c38")))
        s.hline(cx - 4, cx + 4, top + 9, belt)
        if spec.get("sash"):
            sash = s.m("sash", spec["sash"])
            for i in range(9):
                s.px(cx - 3 + i // 2 + 1, top + i, sash)
                s.px(cx - 3 + i // 2 + 2, top + i, sash)
    elif style in ("robe", "long_robe"):
        bottom = top + 22
        s.poly([(cx - 4, top), (cx + 4, top), (cx + 7, bottom), (cx - 7, bottom)], top_m)
        if trim:
            s.hline(cx - 7, cx + 6, bottom, trim)
            s.vline(cx + 4, top, top + 6, trim)
    elif style == "dress":
        bottom = top + 21
        s.poly([(cx - 4, top), (cx + 4, top), (cx + 7, bottom), (cx - 7, bottom)], top_m)
        if spec.get("apron"):
            ap = s.m("apron", spec["apron"])
            s.poly([(cx + 2, top + 7), (cx + 4, top + 7), (cx + 7, bottom - 2), (cx + 3, bottom - 2)], ap)
        bodice = s.m("bodice", spec.get("bodice", spec["top"]))
        s.rect(cx - 4, top, cx + 4, top + 6, bodice)
    elif style == "armor":
        s.poly([(cx - 5, top), (cx + 5, top), (cx + 5, top + 15), (cx - 5, top + 15)], top_m)
        if trim:
            tab = s.m("tabard", spec.get("tabard", spec["trim"]))
            s.rect(cx + 2, top + 3, cx + 5, top + 17, tab)
        pauld = s.m("pauldron", spec.get("pauldron", spec["top"]))
        s.ellipse(cx, top + 2, 4, 3, pauld)

    # front arm
    if arms_pose == "down":
        ax = cx - 1 + stride // 2
        s.rect(ax, top + 1, ax + 2, top + 9, sleeve)
        s.rect(ax, top + 10, ax + 2, top + 11, skin)
        if spec.get("cuffs"):
            iron = s.m("iron", IRON)
            s.hline(ax, ax + 2, top + 9, iron)
    elif arms_pose == "forward":
        s.rect(cx, top + 1, cx + 2, top + 5, sleeve)
        s.rect(cx + 2, top + 4, cx + 8, top + 6, sleeve)
        s.rect(cx + 9, top + 4, cx + 10, top + 6, skin)
        if spec.get("cuffs"):
            iron = s.m("iron", IRON)
            s.vline(cx + 8, top + 4, top + 6, iron)
    elif arms_pose == "raise":
        s.rect(cx, top - 8, cx + 2, top + 2, sleeve)
        s.rect(cx, top - 10, cx + 2, top - 9, skin)
    elif arms_pose == "lantern":
        s.rect(cx, top + 1, cx + 2, top + 7, sleeve)
        s.rect(cx + 2, top + 6, cx + 5, top + 8, sleeve)
        s.rect(cx + 6, top + 6, cx + 7, top + 8, skin)
        frame_m = s.m("lantern_frame", ramp("#2a1c14", "#5a4028", "#8a6440"))
        glass = s.m("lantern_glass", ramp("#c06010", "#ffb040", "#fff0b0"), flat=True, emissive=True)
        s.vline(cx + 7, top + 9, top + 10, frame_m)
        s.rect(cx + 5, top + 11, cx + 9, top + 16, frame_m)
        s.rect(cx + 6, top + 12, cx + 8, top + 15, glass)


# ---------------------------------------------------------------------------
# Public frame builders
# ---------------------------------------------------------------------------
def frame(spec: Dict, direction: str, f: int = 0, expr: str = "neutral", arms: str = "down",
          bob: Optional[int] = None) -> MatSprite:
    s = MatSprite(FW, FH)
    cx = 16
    dy = (-1 if f in (1, 2) else 0) if bob is None else bob
    top = 22 + dy
    hy = 13 + dy
    if direction == "down":
        body_front(s, spec, cx, top, f, back=False, arms_pose=arms)
        head_front(s, spec, cx, hy, expr)
    elif direction == "up":
        body_front(s, spec, cx, top, f, back=True, arms_pose=arms)
        head_back(s, spec, cx, hy)
    else:  # side (right)
        body_side(s, spec, cx - 1, top, f, arms_pose=arms)
        head_side(s, spec, cx - 1, hy, expr)
    return s


def pose_kneel_back(spec: Dict) -> MatSprite:
    """Kneeling, seen from behind (facing the council)."""
    s = MatSprite(FW, FH)
    cx = 16
    top = 29
    skin = _mat(s, spec, "skin")
    top_m = _mat(s, spec, "top")
    legs = s.m("legs", spec.get("legs", spec["top"]))
    iron = s.m("iron", IRON)
    s.ellipse(cx, top + 13, 9, 3.5, legs)
    # soles of the bare feet behind him
    s.rect(cx - 7, top + 15, cx - 4, top + 16, skin, 2)
    s.rect(cx + 3, top + 15, cx + 6, top + 16, skin, 2)
    s.hline(cx - 7, cx - 4, top + 14, iron)
    s.hline(cx + 3, cx + 6, top + 14, iron)
    s.poly([(cx - 7, top), (cx + 7, top), (cx + 8, top + 12), (cx - 8, top + 12)], top_m)
    belt = s.m("belt", spec.get("belt", ramp("#2a1c18", "#4a3428", "#6a4c38")))
    s.hline(cx - 7, cx + 6, top + 8, belt)
    if spec.get("sash"):
        sash = s.m("sash", spec["sash"])
        for i in range(9):
            s.px(cx + 4 - i, top + i, sash)
            s.px(cx + 5 - i, top + i, sash)
    sleeve = s.m("sleeve", spec.get("sleeve", spec["top"]))
    s.rect(cx - 9, top + 1, cx - 7, top + 8, sleeve)
    s.rect(cx + 6, top + 1, cx + 8, top + 8, sleeve)
    head_back(s, spec, cx, top - 9)
    return s


def pose_kneel(spec: Dict, expr: str = "neutral", look_up: bool = False) -> MatSprite:
    """Kneeling front view with shackled hands in front (used in the tribunal)."""
    s = MatSprite(FW, FH)
    cx = 16
    top = 29
    skin = _mat(s, spec, "skin")
    top_m = _mat(s, spec, "top")
    legs = s.m("legs", spec.get("legs", spec["top"]))
    sleeve = s.m("sleeve", spec.get("sleeve", spec["top"]))
    iron = s.m("iron", IRON)
    # folded legs
    s.ellipse(cx, top + 13, 9, 3.5, legs)
    s.rect(cx - 8, top + 14, cx - 5, top + 15, skin)
    s.rect(cx + 4, top + 14, cx + 7, top + 15, skin)
    s.rect(cx - 2, top - 2, cx + 1, top, skin)
    s.poly([(cx - 6, top), (cx + 6, top), (cx + 7, top + 12), (cx - 7, top + 12)], top_m)
    belt = s.m("belt", spec.get("belt", ramp("#2a1c18", "#4a3428", "#6a4c38")))
    s.hline(cx - 6, cx + 5, top + 8, belt)
    # arms hang in front, wrists together
    s.poly([(cx - 9, top + 1), (cx - 6, top + 1), (cx - 1, top + 9), (cx - 4, top + 10)], sleeve)
    s.poly([(cx + 8, top + 1), (cx + 5, top + 1), (cx, top + 9), (cx + 3, top + 10)], sleeve)
    s.rect(cx - 3, top + 9, cx + 2, top + 11, skin)
    s.rect(cx - 4, top + 8, cx + 3, top + 8, iron)
    head_front(s, spec, cx, top - 9 + (0 if not look_up else -1), expr, look_up=look_up)
    return s


def pose_burden(spec: Dict, f: int = 0) -> MatSprite:
    """Bent almost double, palms on the ground: the posture of the Penance."""
    s = MatSprite(FW, FH)
    cx = 16
    skin = _mat(s, spec, "skin")
    top_m = _mat(s, spec, "top")
    legs = s.m("legs", spec.get("legs", spec["top"]))
    sleeve = s.m("sleeve", spec.get("sleeve", spec["top"]))
    iron = s.m("iron", IRON)
    shake = 1 if f == 1 else 0
    # bent legs
    s.rect(cx - 6, 38, cx - 3, 44, legs)
    s.rect(cx + 2, 38, cx + 5, 44, legs)
    s.rect(cx - 7, 44, cx - 3, 45, skin)
    s.rect(cx + 2, 44, cx + 6, 45, skin)
    s.hline(cx - 6, cx - 3, 43, iron)
    s.hline(cx + 2, cx + 5, 43, iron)
    # back carries the weight: a wide flat back
    s.poly([(cx - 9, 24 + shake), (cx + 9, 24 + shake), (cx + 7, 39), (cx - 7, 39)], top_m)
    belt = s.m("belt", spec.get("belt", ramp("#2a1c18", "#4a3428", "#6a4c38")))
    s.hline(cx - 7, cx + 6, 35, belt)
    # arms braced towards the ground
    s.poly([(cx - 10, 26 + shake), (cx - 7, 26 + shake), (cx - 8, 41), (cx - 11, 41)], sleeve)
    s.poly([(cx + 9, 26 + shake), (cx + 6, 26 + shake), (cx + 7, 41), (cx + 10, 41)], sleeve)
    s.rect(cx - 12, 42, cx - 8, 44, skin)
    s.rect(cx + 7, 42, cx + 11, 44, skin)
    s.hline(cx - 11, cx - 8, 41, iron)
    s.hline(cx + 7, cx + 10, 41, iron)
    # head bowed under the shoulders
    hy = 30 + shake
    s.ellipse(cx, hy, 6, 5.5, skin)
    if "hair" in spec:
        hair = _mat(s, spec, "hair")
        s.ellipse(cx, hy - 2, 7, 4.5, hair)
        for x in range(cx - 6, cx + 6, 2):
            s.px(x, hy + 1, hair)
    eye = s.m("eye", spec.get("eye", EYE_DARK), flat=True)
    s.hline(cx - 4, cx - 3, hy + 2, eye)
    s.hline(cx + 2, cx + 3, hy + 2, eye)
    mouth = s.m("mouth", MOUTH, flat=True)
    s.hline(cx - 1, cx, hy + 4, mouth)
    return s


def pose_battle(spec: Dict, kind: str = "idle", f: int = 0) -> MatSprite:
    """Side-view battle poses (facing left in game: we draw facing right, flip in Godot)."""
    s = MatSprite(FW, FH)
    cx = 15
    bob = 1 if f == 1 else 0
    top = 22 + bob
    hy = 13 + bob
    skin = _mat(s, spec, "skin")
    top_m = _mat(s, spec, "top")
    legs = s.m("legs", spec.get("legs", spec["top"]))
    feet = s.m("feet", spec["feet"]) if spec.get("feet") else skin
    sleeve = s.m("sleeve", spec.get("sleeve", spec["top"]))
    iron = s.m("iron", IRON)
    lean = {"idle": 0, "attack": 2, "hurt": -2, "cast": 0, "guard": -1, "down": 0}[kind]
    if kind == "down":
        # collapsed on one knee
        top += 6
        hy += 7
    ly = 37
    # legs in a wide stance
    s.poly([(cx - 3, ly), (cx, ly), (cx - 5, 44), (cx - 8, 44)], legs, 0)
    s.poly([(cx + 1, ly), (cx + 4, ly), (cx + 7, 44), (cx + 4, 44)], legs)
    s.rect(cx - 9, 44, cx - 4, 45, feet, 0)
    s.rect(cx + 4, 44, cx + 9, 45, feet)
    if spec.get("cuffs"):
        s.hline(cx - 7, cx - 4, 43, iron)
        s.hline(cx + 4, cx + 7, 43, iron)
    s.rect(cx - 1 + lean, top - 2, cx + 2 + lean, top, skin)
    s.poly([(cx - 4 + lean, top), (cx + 4 + lean, top), (cx + 5, top + 15), (cx - 5, top + 15)], top_m)
    belt = s.m("belt", spec.get("belt", ramp("#2a1c18", "#4a3428", "#6a4c38")))
    s.hline(cx - 5, cx + 4, top + 9, belt)
    if spec.get("sash"):
        sash = s.m("sash", spec["sash"])
        for i in range(9):
            s.px(cx - 2 + i // 2 + lean, top + i, sash)
            s.px(cx - 1 + i // 2 + lean, top + i, sash)
    chain = s.m("chain", IRON)
    if kind == "idle" or kind == "down":
        s.rect(cx + lean, top + 1, cx + 2 + lean, top + 6, sleeve)
        s.rect(cx + 2 + lean, top + 5, cx + 6 + lean, top + 7, sleeve)
        s.rect(cx + 7 + lean, top + 5, cx + 8 + lean, top + 7, skin)
        s.vline(cx + 6 + lean, top + 5, top + 7, iron)
        # dangling broken chain
        for i in range(6):
            s.px(cx + 8 + lean + (i % 2), top + 8 + i, chain, 2 if i % 2 else 0)
    elif kind == "attack":
        s.rect(cx + lean, top + 1, cx + 2 + lean, top + 4, sleeve)
        s.rect(cx + 2 + lean, top + 2, cx + 9 + lean, top + 4, sleeve)
        s.rect(cx + 10 + lean, top + 2, cx + 11 + lean, top + 4, skin)
        for i in range(5):
            s.px(cx + 12 + lean + i, top + 3 - (i // 2), chain, 2 if i % 2 else 0)
    elif kind == "cast":
        s.rect(cx + lean, top - 8, cx + 2 + lean, top + 2, sleeve)
        s.rect(cx + lean, top - 10, cx + 2 + lean, top - 9, skin)
    elif kind == "guard":
        s.rect(cx + lean, top + 1, cx + 2 + lean, top + 5, sleeve)
        s.rect(cx + 2 + lean, top - 3, cx + 4 + lean, top + 4, sleeve)
        s.rect(cx + 2 + lean, top - 5, cx + 4 + lean, top - 4, skin)
    elif kind == "hurt":
        s.rect(cx - 3 + lean, top + 1, cx - 1 + lean, top + 9, sleeve)
        s.rect(cx - 3 + lean, top + 10, cx - 1 + lean, top + 11, skin)
    expr = {"idle": "angry", "attack": "shout", "hurt": "pain", "cast": "angry", "guard": "angry",
            "down": "pain"}[kind]
    head_side(s, spec, cx + lean, hy, expr)
    return s
