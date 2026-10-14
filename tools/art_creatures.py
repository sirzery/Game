"""Non-humanoid sprites: the Exiled, Synod hound, mossback boar, the goat, crows."""
from __future__ import annotations

import math
import random

from pixel import MatSprite, ramp

FUR = ramp("#120c1c", "#2a1e3a", "#46365e")
FUR_DEEP = ramp("#0a0612", "#160e22", "#241a36")
HORN = ramp("#6a5e50", "#b8ac98", "#ece2cc")
CLAW = ramp("#4a4440", "#9a9088", "#dcd4c8")
EYE_CYAN = ramp("#0a6a7a", "#40e8ff", "#d8ffff")
IRON = ramp("#24232c", "#4e505c", "#8a8c9c")
RUNE = ramp("#0a5a6a", "#36d0f0", "#b0f8ff")


def shade_by_light(s: MatSprite, mid: int, cx: float, cy: float, r: float, strength: float = 0.35,
                   lx: float = -0.7, ly: float = -0.7) -> None:
    """Large-form shading: pixels facing away from the light get the shadow tone."""
    for y in range(s.h):
        for x in range(s.w):
            if int(s.mat[y, x]) != mid or s.tone[y, x] != -1:
                continue
            dx = (x - cx) / r
            dy = (y - cy) / r
            d = dx * lx + dy * ly
            if d < -strength:
                s.tone[y, x] = 0
            elif d > strength + 0.25:
                s.tone[y, x] = 2


def streaks(s: MatSprite, mid: int, seed: int, density: float = 0.08, length: int = 3,
            tone: int = 0) -> None:
    rnd = random.Random(seed)
    for y in range(s.h):
        for x in range(s.w):
            if int(s.mat[y, x]) == mid and rnd.random() < density:
                for k in range(length):
                    yy = y + k
                    if yy < s.h and int(s.mat[yy, x]) == mid:
                        s.tone[yy, x] = tone


# ---------------------------------------------------------------------------
def exiled(kind: str = "idle", f: int = 0) -> MatSprite:
    """The Exiled: a hulking horned beast, facing left, 96x96."""
    s = MatSprite(96, 96)
    fur = s.m("fur", FUR)
    deep = s.m("fur_deep", FUR_DEEP)
    horn = s.m("horn", HORN)
    claw = s.m("claw", CLAW)
    eye = s.m("eye", EYE_CYAN, flat=True, emissive=True)
    rune = s.m("rune", RUNE, flat=True, emissive=True)
    iron = s.m("iron", IRON)
    breath = 1 if f == 1 else 0
    lunge = 6 if kind == "lunge" else 0
    roar = kind == "roar"

    # back legs
    s.poly([(60, 60), (74, 58), (78, 86), (70, 92), (62, 92), (64, 78)], deep)
    s.poly([(44, 64), (56, 62), (58, 88), (50, 92), (40, 92), (46, 80)], fur)
    # massive hunched torso
    s.ellipse(56 - lunge // 2, 50 + breath, 26, 22, fur)
    s.ellipse(64 - lunge // 2, 40 + breath, 18, 16, fur)
    # mane / ragged spine
    for i in range(9):
        x = 46 + i * 5 - lunge // 2
        y = 28 + abs(4 - i) + breath
        s.poly([(x - 3, y + 6), (x + 3, y + 6), (x + 1 + (i % 2), y - 5)], deep)
    # tattered wing-membrane remnants
    s.poly([(70, 34), (92, 14), (90, 30), (94, 38), (84, 44), (88, 52), (74, 50)], deep)
    for (a, b) in ((72, 36), (80, 28), (86, 22)):
        s.line(a, b, a + 6, b + 14, fur)
    # front arm (towards the left), long and clawed
    ax = 30 - lunge
    s.poly([(44, 46 + breath), (54, 50), (40, 80), (30, 84), (ax, 82)], fur)
    s.poly([(ax - 2, 82), (ax + 12, 82), (ax + 10, 88), (ax - 4, 88)], fur)
    for k in range(4):
        s.line(ax - 3 + k * 4, 88, ax - 5 + k * 4, 92, claw)
    # shackle on the wrist and broken chain
    s.rect(ax + 1, 76, ax + 11, 79, iron)
    for i in range(5):
        s.rect(ax + 2 - i * 3, 80 + (i % 2), ax + 3 - i * 3, 81 + (i % 2), iron, 2 if i % 2 else 0)
    # head
    hx = 30 - lunge
    hy = 34 + breath - (6 if roar else 0)
    s.ellipse(hx, hy, 11, 10, fur)
    s.poly([(hx - 18, hy + 4), (hx - 6, hy - 2), (hx - 2, hy + 8), (hx - 14, hy + 10)], fur)  # snout
    # jaw
    if roar:
        s.poly([(hx - 18, hy + 8), (hx - 4, hy + 8), (hx - 2, hy + 18), (hx - 12, hy + 16)], deep)
        mouth = s.m("maw", ramp("#2a0610", "#701830", "#c04060"), flat=True)
        s.poly([(hx - 16, hy + 6), (hx - 4, hy + 6), (hx - 4, hy + 14), (hx - 12, hy + 13)], mouth)
        for k in range(3):
            s.px(hx - 14 + k * 4, hy + 7, claw)
            s.px(hx - 13 + k * 4, hy + 12, claw)
    else:
        s.poly([(hx - 16, hy + 8), (hx - 4, hy + 6), (hx - 2, hy + 12), (hx - 12, hy + 12)], deep)
        s.px(hx - 14, hy + 9, claw)
        s.px(hx - 9, hy + 9, claw)
    # horns sweeping back
    s.poly([(hx - 2, hy - 8), (hx + 4, hy - 9), (hx + 14, hy - 20), (hx + 22, hy - 22), (hx + 12, hy - 14),
            (hx + 4, hy - 4)], horn)
    s.poly([(hx - 6, hy - 6), (hx - 2, hy - 10), (hx - 4, hy - 20), (hx - 10, hy - 26), (hx - 8, hy - 16)], horn)
    # eyes
    s.rect(hx - 7, hy - 1, hx - 4, hy, eye)
    s.rect(hx + 1, hy - 2, hx + 3, hy - 1, eye)
    # glowing runes carved in the fur (the mark of exile)
    for (x, y) in ((58, 44), (62, 48), (66, 44), (60, 54), (70, 52), (52, 50)):
        s.px(x - lunge // 2, y + breath, rune)
    s.hline(56 - lunge // 2, 64 - lunge // 2, 58 + breath, rune)

    shade_by_light(s, fur, 56, 50, 30)
    streaks(s, fur, 7 + f, 0.05, 3, 0)
    streaks(s, deep, 9 + f, 0.04, 2, 2)
    shade_by_light(s, horn, 40, 20, 20, 0.2)
    return s


def hound(kind: str = "idle", f: int = 0) -> MatSprite:
    """Hound of the Synod: pale, lean, gold-masked. Faces right, 48x32."""
    s = MatSprite(48, 32)
    coat = s.m("coat", ramp("#8a8496", "#cfcad6", "#f4f2f8"))
    dark = s.m("coat_dark", ramp("#5a5468", "#8a8496", "#b4aec0"))
    gold = s.m("gold", ramp("#7a5418", "#c8902a", "#f8d870"))
    eye = s.m("eye", ramp("#a04010", "#ffb040", "#fff0b0"), flat=True, emissive=True)
    claw = s.m("claw", CLAW)
    bob = 1 if f == 1 else 0
    lean = {"idle": 0, "attack": 5, "hurt": -3, "crouch": -1}[kind]
    low = 3 if kind == "crouch" else 0
    # legs
    legs = [(12, 0), (16, 2), (30, 0), (34, 2)]
    for i, (lx, off) in enumerate(legs):
        m = dark if off else coat
        st = (2 if (f == 1 and i % 2 == 0) else 0) if kind == "idle" else 0
        x = lx + lean // 2 + (lean // 2 if i >= 2 else 0)
        s.rect(x, 20 + bob + low, x + 2, 28, m)
        s.rect(x - 1 + st, 28, x + 2 + st, 29, claw)
    # body
    s.ellipse(22 + lean // 2, 17 + bob + low, 14, 6, coat)
    s.ellipse(30 + lean, 14 + bob + low, 7, 6, coat)  # chest
    # tail
    s.line(8 + lean // 2, 15 + bob + low, 2, 8 + bob, coat, width=2)
    # neck and head
    hx = 36 + lean
    hy = 9 + bob + low * 2
    s.poly([(28 + lean, 10 + bob + low), (36 + lean, 6 + bob + low), (38 + lean, 14 + bob + low),
            (30 + lean, 18 + bob + low)], coat)
    s.ellipse(hx, hy, 5, 4, coat)
    s.poly([(hx + 2, hy - 2), (hx + 10, hy + 1), (hx + 10, hy + 4), (hx + 2, hy + 4)], coat)
    # ears
    s.poly([(hx - 3, hy - 3), (hx - 1, hy - 9), (hx + 1, hy - 3)], dark)
    # gold mask over the muzzle and harness
    s.poly([(hx - 1, hy - 3), (hx + 9, hy), (hx + 9, hy + 2), (hx - 1, hy + 1)], gold)
    s.rect(hx + 2, hy - 1, hx + 3, hy, eye)
    # collar and a strap along the spine (no cross shapes)
    s.vline(31 + lean, 9 + bob + low, 16 + bob + low, gold)
    s.vline(32 + lean, 9 + bob + low, 16 + bob + low, gold)
    s.hline(14 + lean // 2, 28 + lean // 2, 11 + bob + low, gold)
    if kind == "attack":
        maw = s.m("maw", ramp("#2a0610", "#701830", "#c04060"), flat=True)
        s.rect(hx + 4, hy + 4, hx + 9, hy + 5, maw)
        s.px(hx + 5, hy + 4, claw)
        s.px(hx + 8, hy + 4, claw)
    shade_by_light(s, coat, 22, 14, 14, 0.4)
    return s


def boar(kind: str = "idle", f: int = 0) -> MatSprite:
    """Mossback boar, faces right, 48x32."""
    s = MatSprite(48, 32)
    hide = s.m("hide", ramp("#2a1a14", "#4e3426", "#74503a"))
    moss = s.m("moss", ramp("#1e3a1a", "#3e6a2a", "#6a9a3e"))
    tusk = s.m("tusk", ramp("#a09a88", "#e4dccc", "#ffffff"))
    hoof = s.m("hoof", ramp("#14100e", "#2a2420", "#40382e"))
    eye = s.m("eye", ramp("#5a1010", "#e03030", "#ff9090"), flat=True, emissive=True)
    bob = 1 if f == 1 else 0
    lean = {"idle": 0, "attack": 6, "hurt": -3}[kind]
    for i, lx in enumerate((12, 17, 29, 34)):
        x = lx + lean // 2
        s.rect(x, 22 + bob, x + 3, 28, hide)
        s.rect(x, 28, x + 3, 29, hoof)
    s.ellipse(23 + lean // 2, 17 + bob, 15, 9, hide)
    s.ellipse(36 + lean, 17 + bob, 7, 7, hide)
    s.poly([(40 + lean, 15 + bob), (47 + lean, 18 + bob), (46 + lean, 23 + bob), (40 + lean, 22 + bob)], hide)
    s.rect(45 + lean, 18 + bob, 46 + lean, 20 + bob, hoof)
    # moss and little mushrooms along the back
    for i in range(12):
        x = 11 + i * 2 + lean // 2
        s.ellipse(x, 9 + bob + abs(6 - i) // 3, 2.5, 2, moss)
    shroom = s.m("shroom", ramp("#6a1a1a", "#c04030", "#f08060"))
    s.rect(18 + lean // 2, 5 + bob, 20 + lean // 2, 6 + bob, shroom)
    s.rect(27 + lean // 2, 6 + bob, 28 + lean // 2, 7 + bob, shroom)
    # tusks
    s.line(42 + lean, 22 + bob, 45 + lean, 17 + bob, tusk)
    s.px(39 + lean, 14 + bob, eye)
    s.poly([(33 + lean, 10 + bob), (35 + lean, 6 + bob), (37 + lean, 11 + bob)], hide)
    shade_by_light(s, hide, 23, 14, 16, 0.35)
    streaks(s, hide, 3 + f, 0.06, 2, 0)
    return s


def goat(kind: str = "idle", f: int = 0) -> MatSprite:
    """'Pangeran' the goat. Faces right, 28x24."""
    s = MatSprite(28, 24)
    wool = s.m("wool", ramp("#a8a0a0", "#e8e2dc", "#ffffff"))
    dark = s.m("wool_dark", ramp("#6a6060", "#9a9090", "#c4bcbc"))
    horn = s.m("horn", ramp("#5a4a3a", "#8a7458", "#b49a78"))
    hoof = s.m("hoof", ramp("#1a1414", "#3a2e2a", "#5a4a40"))
    ribbon = s.m("ribbon", ramp("#6a1020", "#c02838", "#f06070"))
    bell = s.m("bell", ramp("#7a5418", "#d8a030", "#fff0a0"))
    eye = s.m("eye", ramp("#141010", "#2a201a", "#4a3a2a"), flat=True)
    bob = 1 if f == 1 else 0
    step = 1 if (kind == "walk" and f == 1) else 0
    for i, lx in enumerate((6, 9, 15, 18)):
        x = lx + (step if i % 2 == 0 else -step)
        s.rect(x, 15, x + 1, 20, dark if i % 2 else wool)
        s.rect(x, 21, x + 1, 21, hoof)
    s.ellipse(12, 12 + bob, 8, 5, wool)
    s.px(3, 9 + bob, wool)
    s.px(2, 8 + bob, wool)  # tail
    # head
    hy = 7 + bob + (3 if kind == "eat" else 0)
    s.ellipse(21, hy, 3.5, 3.5, wool)
    s.poly([(22, hy), (26, hy + 2), (25, hy + 4), (21, hy + 3)], wool)
    s.px(23, hy + 5, dark)
    s.px(23, hy + 6, dark)  # beard
    s.px(22, hy - 1, eye)
    s.line(20, hy - 3, 18, hy - 6, horn)
    s.px(17, hy - 6, horn)
    s.line(18, hy - 2, 16, hy - 1, wool)  # ear
    s.rect(19, hy + 3, 21, hy + 4, ribbon)
    s.px(20, hy + 5, bell)
    if kind == "eat":
        bread = s.m("bread", ramp("#7a4a1a", "#c08040", "#f0c070"))
        s.rect(25, hy + 3, 27, hy + 5, bread)
    return s


def crow(f: int = 0) -> MatSprite:
    s = MatSprite(14, 12)
    body = s.m("crow", ramp("#08060c", "#18141e", "#2e2838"))
    beak = s.m("beak", ramp("#3a3020", "#6a5a3a", "#9a8858"))
    eye = s.m("eye", ramp("#801010", "#ff3030", "#ffa0a0"), flat=True, emissive=True)
    if f == 0:
        s.ellipse(7, 7, 4, 3, body)
        s.ellipse(10, 4, 2.5, 2.5, body)
        s.px(13, 4, beak)
        s.px(10, 3, eye)
        s.line(3, 7, 1, 9, body)
        s.vline(6, 10, 11, beak)
        s.vline(8, 10, 11, beak)
    else:
        s.ellipse(7, 7, 4, 2.5, body)
        s.ellipse(11, 6, 2, 2, body)
        s.px(13, 6, beak)
        s.px(11, 5, eye)
        s.poly([(4, 6), (8, 6), (5, 0), (2, 1)], body)
    return s


def light_lance() -> MatSprite:
    s = MatSprite(56, 9)
    core = s.m("core", ramp("#fff6c8", "#ffffff", "#ffffff"), flat=True, emissive=True, no_outline=True)
    glow = s.m("glow", ramp("#c08a20", "#ffd060", "#fff0b0"), flat=True, emissive=True, no_outline=True)
    s.poly([(0, 4), (8, 1), (50, 3), (56, 4), (50, 5), (8, 7)], glow)
    s.poly([(2, 4), (10, 3), (48, 4), (10, 5)], core)
    s.poly([(38, 0), (44, 4), (38, 8), (40, 4)], glow)
    return s
