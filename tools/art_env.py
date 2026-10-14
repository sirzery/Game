"""Environment art for DOSIER: backgrounds, props and their normal/emissive maps."""
from __future__ import annotations

import math
import random
from typing import Dict, List, Sequence, Tuple

import numpy as np

from pixel import (MatSprite, RGB, bayer, blur, hexc, lerp_palette, mix, new_img, normal_from_height,
                   paste, quantize, ramp, value_noise)


def _hash2(a: np.ndarray, b: np.ndarray, seed: int) -> np.ndarray:
    a = np.asarray(a).astype(np.int64)
    b = np.asarray(b).astype(np.int64)
    with np.errstate(over="ignore"):
        v = (a * np.int64(73856093)) ^ (b * np.int64(19349663)) ^ np.int64(seed * 83492791)
        v = (v ^ (v >> 13)) * np.int64(1274126177)
        v = v ^ (v >> 16)
    return (v & 0xFFFF) / 65535.0


def pal(*hexes: str) -> List[RGB]:
    return [hexc(h) for h in hexes]


def shade_rgb(img: np.ndarray, factor: np.ndarray) -> None:
    img[..., :3] = np.clip(img[..., :3].astype(np.float32) * factor[..., None], 0, 255).astype(np.uint8)


def to_img(values: np.ndarray, palette: Sequence[RGB], dither: float = 0.6) -> np.ndarray:
    return quantize(np.clip(values, 0, 0.999), palette, dither)


# ---------------------------------------------------------------------------
# Generic surfaces
# ---------------------------------------------------------------------------
def brick_surface(w: int, h: int, bw: int, bh: int, seed: int) -> Tuple[np.ndarray, np.ndarray]:
    """Returns (value 0..1, height 0..1) for a staggered brick wall."""
    yy, xx = np.mgrid[0:h, 0:w]
    row = yy // bh
    off = (row % 2) * (bw // 2)
    col = (xx + off) // bw
    lx = (xx + off) % bw
    ly = yy % bh
    mortar = (lx == 0) | (ly == 0)
    rnd = _hash2(row, col, seed)
    n = value_noise(w, h, 6, seed + 1, 3)
    val = 0.45 + rnd * 0.25 + (n - 0.5) * 0.35
    # bevel: lighter top rows, darker bottom rows of each brick
    val = val + np.where(ly == 1, 0.12, 0) - np.where(ly == bh - 1, 0.12, 0)
    val = val + np.where(lx == 1, 0.06, 0) - np.where(lx == bw - 1, 0.08, 0)
    val = np.where(mortar, 0.08 + n * 0.1, val)
    height = np.where(mortar, 0.0, 0.8 + n * 0.2)
    # cracks & chips
    chips = value_noise(w, h, 3, seed + 7, 2) > 0.78
    val = np.where(chips & ~mortar, val - 0.18, val)
    return np.clip(val, 0, 1), height


def tile_floor(w: int, h: int, tw: int, th: int, seed: int) -> Tuple[np.ndarray, np.ndarray]:
    yy, xx = np.mgrid[0:h, 0:w]
    tx = xx // tw
    ty = yy // th
    lx = xx % tw
    ly = yy % th
    grout = (lx == 0) | (ly == 0)
    checker = ((tx + ty) % 2).astype(np.float64)
    n = value_noise(w, h, 10, seed, 4)
    veins = np.abs(value_noise(w, h, 18, seed + 3, 3) - 0.5) < 0.03
    val = 0.35 + checker * 0.3 + (n - 0.5) * 0.25
    val = np.where(veins, val + 0.12, val)
    val = val + np.where(ly == 1, 0.07, 0) - np.where(ly == th - 1, 0.06, 0)
    val = np.where(grout, 0.1, val)
    height = np.where(grout, 0.0, 0.7 + n * 0.1)
    return np.clip(val, 0, 1), height


def rgba_from(val: np.ndarray, palette: Sequence[RGB], dither: float = 0.6) -> np.ndarray:
    return to_img(val, palette, dither)


# ---------------------------------------------------------------------------
# Stained glass
# ---------------------------------------------------------------------------
GLASS = [hexc(h) for h in ("#b0182c", "#d8a030", "#2a4ab0", "#6a2a9a", "#1a8a7a", "#e05a20")]


def stained_window(w: int, h: int, seed: int, motif: str = "eye") -> Tuple[np.ndarray, np.ndarray]:
    """Arched window. Returns (colour RGBA, emissive RGBA)."""
    rnd = random.Random(seed)
    img = new_img(w, h)
    emi = new_img(w, h)
    cx = (w - 1) / 2.0
    r = w / 2.0
    lead = hexc("#141018")
    frame_c = [hexc("#2a2430"), hexc("#4a4250"), hexc("#6a6070")]
    # random pane colour per cell of a diamond lattice
    for y in range(h):
        for x in range(w):
            # arch shape
            if y < r:
                dx = (x + 0.5 - cx) / r
                dy = (y + 0.5 - r) / r
                if dx * dx + dy * dy > 1.0:
                    continue
                inner = dx * dx + dy * dy < 0.78
            else:
                inner = 2 <= x < w - 2 and y < h - 2
            if not inner:
                c = frame_c[1 if x < cx else 0]
                img[y, x] = (*c, 255)
                continue
            u = (x + y * 0.5) // 6
            v = (x - y * 0.5) // 6
            is_lead = ((x + y * 0.5) % 6 < 1) or ((x - y * 0.5) % 6 < 1)
            k = int(_hash2(np.array(u), np.array(v), seed) * len(GLASS)) % len(GLASS)
            col = GLASS[k]
            # central motif
            my = h * 0.45
            d = math.hypot(x + 0.5 - cx - 0.5, (y + 0.5 - my) * 0.9)
            if motif == "eye":
                if d < w * 0.22:
                    is_lead = False
                    col = hexc("#ffd860") if d > w * 0.11 else hexc("#fff4c0")
                    if d < w * 0.07:
                        col = hexc("#b0182c")
                    if abs(d - w * 0.22) < 1.0 or abs(d - w * 0.11) < 0.8:
                        is_lead = True
            elif motif == "figure":
                if abs(x + 0.5 - cx - 0.5) < w * 0.12 and h * 0.3 < y < h * 0.85:
                    col = hexc("#f0e6d0")
                    is_lead = (y % 7 == 0)
                if math.hypot(x + 0.5 - cx - 0.5, y - h * 0.26) < w * 0.12:
                    col = hexc("#ffd860")
                    is_lead = False
            if is_lead:
                img[y, x] = (*lead, 255)
            else:
                shade = 0.82 + 0.18 * rnd.random()
                c = tuple(int(min(255, v * shade)) for v in col)
                img[y, x] = (*c, 255)
                emi[y, x] = (*c, 255)
    return img, emi


# ---------------------------------------------------------------------------
# Tribunal hall
# ---------------------------------------------------------------------------
STONE_PAL = pal("#0c0a12", "#16121e", "#211b2b", "#2d2539", "#3a3048", "#4a3e58", "#5c4e6a")
MARBLE_PAL = pal("#100c14", "#1e1820", "#2c2430", "#3c3240", "#4e4250", "#625464", "#7a6a78", "#948290")
CARPET_PAL = pal("#1e0408", "#38070e", "#560c16", "#741420", "#901c2a")
GOLD_PAL = pal("#3a2408", "#6a4414", "#9a6a20", "#c8902a", "#f0c050", "#fff0a0")
WOOD_PAL = pal("#120a08", "#22140e", "#341e14", "#4a2c1c", "#603c26")


def tribunal() -> Dict[str, np.ndarray]:
    W, H = 480, 270
    wall_h = 150
    out = {}
    img = new_img(W, H)
    height = np.zeros((H, W))
    emi = new_img(W, H)
    # back wall
    wv, wh = brick_surface(W, wall_h, 16, 8, 11)
    grad = np.linspace(0.75, 1.05, wall_h)[:, None]
    img[:wall_h] = rgba_from(wv * grad, STONE_PAL)
    height[:wall_h] = wh * 0.6
    # floor
    fh = H - wall_h
    fv, fhgt = tile_floor(W, fh, 24, 14, 21)
    depth = np.linspace(0.7, 1.0, fh)[:, None]
    img[wall_h:] = rgba_from(fv * depth, MARBLE_PAL)
    height[wall_h:] = fhgt * 0.5
    # wall base moulding
    for y in range(wall_h - 6, wall_h):
        t = (y - (wall_h - 6)) / 6
        c = STONE_PAL[5] if y == wall_h - 6 else STONE_PAL[3 - int(t * 2)]
        img[y, :, :3] = c
        height[y, :] = 0.9 - t * 0.4
    # windows
    for i, cxw in enumerate((96, 240, 384)):
        ww, hh = 40, 98
        motif = "eye" if i == 1 else "figure"
        wimg, wemi = stained_window(ww, hh, 30 + i, motif)
        x0, y0 = cxw - ww // 2, 18
        paste(img, wimg, x0, y0)
        paste(emi, wemi, x0, y0)
        height[y0:y0 + hh, x0:x0 + ww] = np.where(wimg[..., 3] > 0, 0.2, height[y0:y0 + hh, x0:x0 + ww])
        # window sill
        img[y0 + hh:y0 + hh + 3, x0 - 3:x0 + ww + 3, :3] = STONE_PAL[5]
        img[y0 + hh + 2, x0 - 3:x0 + ww + 3, :3] = STONE_PAL[2]
    # banners between windows
    for bx in (168, 312):
        _banner(img, bx - 9, 22)
    # dais (raised platform with steps)
    dx0, dx1 = 120, 360
    for step in range(4):
        y = 132 + step * 7
        x0 = dx0 - step * 10
        x1 = dx1 + step * 10
        top = STONE_PAL[5] if step else STONE_PAL[6]
        img[y:y + 7, x0:x1, :3] = STONE_PAL[4]
        img[y, x0:x1, :3] = top
        img[y + 6, x0:x1, :3] = STONE_PAL[2]
        height[y:y + 7, x0:x1] = 1.0 - step * 0.15
        height[y + 6, x0:x1] = 0.1
    # carpet from the dais to the bottom
    cx0, cx1 = 216, 264
    cv = value_noise(cx1 - cx0, H - 160, 4, 5, 2)
    carpet = rgba_from(0.3 + cv * 0.5, CARPET_PAL)
    img[160:, cx0:cx1] = carpet
    img[160:, cx0:cx0 + 2, :3] = GOLD_PAL[3]
    img[160:, cx1 - 2:cx1, :3] = GOLD_PAL[2]
    for y in range(166, H, 18):
        img[y:y + 1, cx0 + 6:cx1 - 6, :3] = GOLD_PAL[2]
    height[160:, cx0:cx1] = 0.55
    # council bench on the dais (long and imposing)
    bx0, bx1 = 140, 340
    img[106:132, bx0:bx1, :3] = WOOD_PAL[2]
    for x in range(bx0, bx1, 20):
        img[106:132, x:x + 2, :3] = WOOD_PAL[1]
    img[106:108, bx0:bx1, :3] = GOLD_PAL[3]
    img[130:132, bx0:bx1, :3] = WOOD_PAL[0]
    height[106:132, bx0:bx1] = 0.9
    # sigil on the bench front
    for y in range(112, 128):
        for x in range(232, 248):
            d = math.hypot(x - 239.5, y - 119.5)
            if 5.5 < d < 7.2 or d < 2.2:
                img[y, x, :3] = GOLD_PAL[4]
                emi[y, x] = (*GOLD_PAL[4], 255)
    nm = normal_from_height(blur(height, 1), 3.0)
    out["color"] = img
    out["normal"] = nm
    out["emissive"] = emi
    return out


def _banner(img: np.ndarray, x0: int, y0: int) -> None:
    w, h = 18, 64
    for y in range(h):
        for x in range(w):
            tail = y > h - 8 and abs(x - w / 2 + 0.5) < (y - (h - 8)) * 1.2
            if tail:
                continue
            c = CARPET_PAL[3] if x > 1 else CARPET_PAL[1]
            if x >= w - 2:
                c = CARPET_PAL[2]
            img[y0 + y, x0 + x, :3] = c
            img[y0 + y, x0 + x, 3] = 255
    for y in range(18, 34):
        for x in range(w):
            d = math.hypot(x - w / 2 + 0.5, y - 26)
            if 4.5 < d < 6 or d < 1.8:
                img[y0 + y, x0 + x, :3] = GOLD_PAL[4]
    img[y0, x0 - 2:x0 + w + 2, :3] = GOLD_PAL[2]
    img[y0 + 1, x0 - 2:x0 + w + 2, :3] = GOLD_PAL[3]


def pillar(h: int = 170) -> Tuple[np.ndarray, np.ndarray]:
    w = 30
    img = new_img(w, h)
    height = np.zeros((h, w))
    n = value_noise(w, h, 5, 77, 3)
    for y in range(h):
        for x in range(w):
            cap = y < 12 or y >= h - 14
            half = 15 if cap else 11
            if abs(x - 14.5) > half:
                continue
            # cylinder shading (light from left)
            t = (x - 14.5 + half) / (2 * half)
            v = 0.85 - t * 0.6 + (n[y, x] - 0.5) * 0.2
            flute = (not cap) and (x % 5 == 2)
            if flute:
                v -= 0.15
            if cap and (y in (3, 10) or y in (h - 12, h - 4)):
                v -= 0.2
            idx = int(np.clip(v * len(STONE_PAL), 0, len(STONE_PAL) - 1))
            img[y, x] = (*STONE_PAL[idx], 255)
            height[y, x] = math.sqrt(max(0.0, 1 - ((x - 14.5) / half) ** 2))
    nm = normal_from_height(height, 2.5, img[..., 3])
    return img, nm


def candelabra() -> np.ndarray:
    s = MatSprite(16, 34)
    iron = s.m("iron", ramp("#14121a", "#2e2c36", "#4e4c5a"))
    gold = s.m("gold", ramp("#6a4414", "#c8902a", "#f8d870"))
    wax = s.m("wax", ramp("#b0a890", "#e8e0c8", "#fffaf0"), flat=True)
    s.rect(7, 12, 8, 31, iron)
    s.rect(4, 31, 11, 33, iron)
    s.rect(2, 12, 13, 13, gold)
    for x in (2, 7, 12):
        s.rect(x, 6, x + 1, 11, wax)
    return s.render()


def flame_frames() -> List[np.ndarray]:
    frames = []
    for f in range(4):
        img = new_img(6, 8)
        sway = (0, 1, 0, -1)[f]
        cols = [hexc("#ff7a20"), hexc("#ffc040"), hexc("#fff4c0")]
        for y in range(8):
            wdt = [0, 1, 1, 2, 2, 2, 1, 1][y]
            cxp = 2.5 + sway * (1 - y / 8)
            for x in range(6):
                d = abs(x - cxp)
                if d <= wdt:
                    c = cols[0] if d > wdt - 0.6 else (cols[1] if y < 6 else cols[2])
                    if y >= 5 and d < 0.8:
                        c = cols[2]
                    img[y, x] = (*c, 255)
        frames.append(img)
    return frames


# ---------------------------------------------------------------------------
# Peak of Penance
# ---------------------------------------------------------------------------
ROCK_PAL = pal("#08070c", "#100e16", "#191520", "#231e2b", "#2e2836", "#3a3342", "#484050", "#58505e",
               "#6a6270")
SNOW_PAL = pal("#5a6478", "#8a94aa", "#b8c2d4", "#e2e8f2", "#ffffff")
PINE_DARK = pal("#060a0c", "#0c1416", "#142020", "#1c2c28")


def voronoi_facets(w: int, h: int, count: int, seed: int,
                   light: Tuple[float, float, float] = (-0.55, -0.6, 0.58)):
    """Flat-shaded rock facets. Returns (brightness 0..1, cell id, border mask)."""
    rng = np.random.default_rng(seed)
    pts = np.stack([rng.uniform(0, w, count), rng.uniform(0, h, count)], 1)
    # each facet gets a random normal biased towards the viewer
    nrm = rng.normal(0, 1, (count, 3))
    nrm[:, 2] = np.abs(nrm[:, 2]) + 1.2
    nrm /= np.linalg.norm(nrm, axis=1, keepdims=True)
    lv = np.array(light)
    lv = lv / np.linalg.norm(lv)
    bright = np.clip(nrm @ lv, 0, 1)
    yy, xx = np.mgrid[0:h, 0:w]
    best = np.full((h, w), 1e12)
    second = np.full((h, w), 1e12)
    cid = np.zeros((h, w), np.int32)
    for i in range(count):
        d = (xx - pts[i, 0]) ** 2 + (yy - pts[i, 1]) ** 2 * 1.6
        closer = d < best
        second = np.where(closer, best, np.minimum(second, d))
        cid = np.where(closer, i, cid)
        best = np.where(closer, d, best)
    border = (np.sqrt(second) - np.sqrt(best)) < 1.2
    return bright[cid], cid, border


def colossal_stone() -> Dict[str, np.ndarray]:
    """A mountain torn from the earth, chained to the Scholar's back. 360x560."""
    W, H = 360, 560
    yy, xx = np.mgrid[0:H, 0:W]
    cx = W / 2
    # silhouette: craggy mountain on top, rounded underside that narrows to the contact point
    prof = value_noise(W, 1, 18, 101, 4)[0]
    prof2 = value_noise(W, 1, 5, 102, 3)[0]
    rel = np.abs(np.arange(W) - cx) / (W / 2)
    peak_top = 30 + (rel ** 1.2) * 300 + (prof - 0.5) * 70 + (prof2 - 0.5) * 18
    under = H - 20 - (rel ** 2.2) * 210 + (prof2 - 0.5) * 10
    mask = (yy >= peak_top[None, :]) & (yy <= under[None, :])
    # big-form shading: sphere-ish with light from upper left
    ny = (yy - H * 0.55) / (H * 0.55)
    nx = (xx - cx) / (W * 0.5)
    form = 0.5 - nx * 0.3 - ny * 0.2
    n1 = value_noise(W, H, 40, 103, 5)
    n2 = value_noise(W, H, 8, 104, 3)
    # faceted crags: voronoi cells, each with its own tilted face normal
    facets, cell_id, border = voronoi_facets(W, H, 260, 107)
    strata = np.sin((yy + n1 * 60) / 7.0) * 0.04
    val = form * 0.6 + facets * 0.55 + (n2 - 0.5) * 0.18 + strata - 0.05
    val = np.where(border, val - 0.18, val)
    ridge = 1 - np.abs(value_noise(W, H, 26, 105, 4) * 2 - 1)
    img = rgba_from(np.clip(val, 0, 1), ROCK_PAL, 0.7)
    # snow on the upper slopes
    snow_line = peak_top + 40 + (value_noise(W, 1, 7, 106, 3)[0] - 0.5) * 50
    snow = mask & (yy < snow_line[None, :]) & (n2 > 0.35 - (snow_line[None, :] - yy) / 200)
    snow_val = np.clip(0.55 - nx * 0.4 + (n2 - 0.5) * 0.4, 0, 0.999)
    simg = rgba_from(snow_val, SNOW_PAL, 0.7)
    img[snow] = simg[snow]
    # dark underside
    under_shadow = mask & (yy > under[None, :] - 60)
    fac = np.where(under_shadow, 1 - (yy - (under[None, :] - 60)) / 120.0, 1.0)
    shade_rgb(img, np.clip(fac, 0.45, 1.0))
    img[..., 3] = np.where(mask, 255, 0)
    # outline pass
    m2 = mask.copy()
    edge = m2 & ~(np.roll(m2, 1, 0) & np.roll(m2, -1, 0) & np.roll(m2, 1, 1) & np.roll(m2, -1, 1))
    img[edge, :3] = hexc("#08060a")
    # tiny pines on the slopes
    rnd = random.Random(7)
    for _ in range(26):
        x = rnd.randint(40, W - 40)
        top = int(peak_top[x])
        y = top + rnd.randint(30, 120)
        if y + 10 < H and mask[y, x] and mask[min(H - 1, y + 10), x]:
            _tiny_pine(img, x, y, rnd.randint(7, 12))
    # rune bands (emissive layer) that bind the stone
    emi = new_img(W, H)
    height = np.where(mask, 0.5 + facets * 0.5 + (n1 - 0.5) * 0.4 - border * 0.3, 0.0)
    for band_y, amp in ((H - 150, 14), (H - 260, 22)):
        for x in range(W):
            y = int(band_y + math.sin(x / 40.0) * amp - (rel[x] ** 2) * 40)
            if 0 <= y < H and mask[y, x]:
                glyph = (x // 6) % 4
                for k in range(3):
                    yk = y + k - 1
                    if not (0 <= yk < H and mask[yk, x]):
                        continue
                    on = k == 1 or (glyph == 0 and k == 0) or (glyph == 2 and k == 2) or (x % 6 == 0)
                    if on:
                        c = hexc("#40e8ff") if k == 1 else hexc("#a8f6ff")
                        img[yk, x, :3] = mix(c, (20, 40, 60), 0.35)
                        emi[yk, x] = (*c, 255)
    # the carved sigil of the Synod on the underside
    sx, sy = int(cx), H - 70
    for y in range(sy - 16, sy + 17):
        for x in range(sx - 16, sx + 17):
            d = math.hypot(x - sx, y - sy)
            if (13 < d < 15.5) or (6 < d < 7.5) or (d < 2.5) or (abs(y - sy) < 1 and d < 13):
                if mask[y, x]:
                    emi[y, x] = (*hexc("#40e8ff"), 255)
                    img[y, x, :3] = hexc("#1a5a6a")
    nm = normal_from_height(blur(height, 2), 4.0, img[..., 3])
    return {"color": img, "normal": nm, "emissive": emi}


def _tiny_pine(img: np.ndarray, x: int, y: int, h: int) -> None:
    H, W = img.shape[:2]
    for k in range(h):
        wdt = int((k / h) * h * 0.4) + 1
        for dx in range(-wdt, wdt + 1):
            xx, yy = x + dx, y - h + k
            if 0 <= xx < W and 0 <= yy < H:
                c = PINE_DARK[1] if dx > 0 else PINE_DARK[3]
                if k % 3 == 0 and abs(dx) == wdt:
                    c = SNOW_PAL[2]
                img[yy, xx] = (*c, 255)
    if 0 <= y < H:
        img[y, x] = (*WOOD_PAL[1], 255)


def mountains_layer(w: int, h: int, seed: int, base: float, rough: float, palette: Sequence[RGB],
                    snow: bool = False) -> np.ndarray:
    xs = np.arange(w)
    prof = value_noise(w, 1, w / 5, seed, 5)[0]
    ridge = h - (base + prof * rough * h)
    yy, xx = np.mgrid[0:h, 0:w]
    mask = yy >= ridge[None, :]
    dslope = np.gradient(ridge)
    lit = np.clip(0.5 - dslope[None, :] * 0.6, 0, 1)
    depth = (yy - ridge[None, :]) / h
    val = np.clip(lit * 0.6 + 0.3 - depth * 0.8 + (value_noise(w, h, 12, seed + 1, 3) - 0.5) * 0.2, 0, 0.999)
    img = rgba_from(val, palette, 0.7)
    if snow:
        sm = mask & (yy < ridge[None, :] + 2 + value_noise(w, h, 4, seed + 2, 2) * 5) & (lit > 0.45)
        img[sm, :3] = mix(palette[-1], (200, 210, 235), 0.3)
    img[..., 3] = np.where(mask, 255, 0)
    return img


def cliff_ground(w: int, h: int, seed: int) -> Dict[str, np.ndarray]:
    yy, xx = np.mgrid[0:h, 0:w]
    edge = 6 + value_noise(w, 1, 20, seed, 4)[0] * 14
    mask = yy >= edge[None, :]
    n = value_noise(w, h, 9, seed + 1, 4)
    cracks = np.abs(value_noise(w, h, 14, seed + 2, 3) - 0.5) < 0.025
    val = 0.25 + n * 0.45 - (yy / h) * 0.15
    val = np.where(cracks, val - 0.2, val)
    rim = mask & (yy < edge[None, :] + 3)
    val = np.where(rim, val + 0.2, val)
    img = rgba_from(np.clip(val, 0, 0.999), ROCK_PAL, 0.8)
    img[..., 3] = np.where(mask, 255, 0)
    height = np.where(mask, n * 0.8 - cracks * 0.4, 0)
    nm = normal_from_height(blur(height, 1), 3.0, img[..., 3])
    return {"color": img, "normal": nm}


def iron_stake() -> np.ndarray:
    s = MatSprite(14, 26)
    iron = s.m("iron", ramp("#14121a", "#3a3a46", "#6a6c7c"))
    rust = s.m("rust", ramp("#3a1a10", "#6a3018", "#8a4a28"))
    s.poly([(5, 8), (9, 8), (8, 25), (6, 25)], iron)
    s.ellipse(7, 5, 5, 4.5, iron)
    s.ellipse(7, 5, 2.5, 2, s.m("hole", ramp("#000000", "#000000", "#000000")))
    for x in range(6, 9):
        s.px(x, 15, rust)
    s.px(6, 19, rust)
    s.rect(2, 24, 12, 25, s.m("rock", (ROCK_PAL[2], ROCK_PAL[4], ROCK_PAL[6])))
    img = s.render()
    # punch the hole transparent
    img[(img[..., 0] == 0) & (img[..., 1] == 0) & (img[..., 2] == 0)] = (0, 0, 0, 0)
    return img


def chain_link() -> np.ndarray:
    """Horizontal tileable chain texture 8x6 for Line2D (tile mode)."""
    img = new_img(8, 6)
    dark, mid, light = hexc("#1a1820"), hexc("#55566a"), hexc("#9a9cb0")
    # oval link seen from the side
    for x in range(0, 5):
        img[1, x] = (*light, 255)
        img[4, x] = (*mid, 255)
        img[0, x] = (*dark, 255)
        img[5, x] = (*dark, 255)
    img[2, 0] = img[3, 0] = (*mid, 255)
    img[2, 4] = img[3, 4] = (*dark, 255)
    # link seen edge-on
    for x in range(4, 8):
        img[2, x] = (*light, 255)
        img[3, x] = (*mid, 255)
    return img


# ---------------------------------------------------------------------------
# Forest / wilds
# ---------------------------------------------------------------------------
GRASS_PAL = pal("#0e1a12", "#16261a", "#1e3420", "#284428", "#34562e", "#446a34", "#567e3a", "#6c9442")
DIRT_PAL = pal("#1a120e", "#2a1e16", "#3a2a1e", "#4c3826", "#5e4830", "#725a3c")
WATER_PAL = pal("#0a1a2a", "#10283c", "#18384e", "#224a62", "#2e6078", "#4a8296", "#7ab0c0")
LEAF_PAL = pal("#08120c", "#0e1c12", "#162a18", "#1e3a1e", "#284822", "#34582a", "#426a30", "#527a36")
AUTUMN_PAL = pal("#120c0a", "#1c120c", "#2a1a10", "#382214", "#462a18", "#54321c", "#623c22", "#704628")
BARK_PAL = pal("#0e0806", "#1a100a", "#28180e", "#382214", "#4a2e1a")


def wilds_ground(w: int, h: int) -> Dict[str, np.ndarray]:
    yy, xx = np.mgrid[0:h, 0:w]
    n = value_noise(w, h, 40, 201, 5)
    n2 = value_noise(w, h, 6, 202, 3)
    val = 0.25 + n * 0.5 + (n2 - 0.5) * 0.3
    img = rgba_from(np.clip(val, 0, 0.999), GRASS_PAL, 0.9)
    height = n * 0.5 + n2 * 0.4
    # dirt path: from the west edge winding to the village in the east
    path_y = h * 0.55 + np.sin(np.arange(w) / 90.0) * 60 + (value_noise(w, 1, 50, 203, 3)[0] - 0.5) * 50
    pw = 13 + value_noise(w, 1, 20, 204, 2)[0] * 8
    dist = np.abs(yy - path_y[None, :])
    path = dist < pw[None, :] + (n2 - 0.5) * 8
    dval = 0.3 + n2 * 0.5 + (n - 0.5) * 0.3 - dist / 60.0
    dimg = rgba_from(np.clip(dval, 0, 0.999), DIRT_PAL, 0.9)
    img[path] = dimg[path]
    height = np.where(path, 0.2 + n2 * 0.2, height)
    # a small stream running north-south in the west part
    sx = w * 0.22 + np.sin(np.arange(h) / 45.0) * 18 + (value_noise(h, 1, 30, 205, 3)[0] - 0.5) * 30
    sd = np.abs(xx - sx[:, None])
    stream = sd < 9 + (n2 - 0.5) * 4
    bank = (sd < 12 + (n2 - 0.5) * 4) & ~stream
    wv = 0.35 + value_noise(w, h, 5, 206, 2) * 0.4 - sd / 30.0
    wimg = rgba_from(np.clip(wv, 0, 0.999), WATER_PAL, 0.8)
    img[stream] = wimg[stream]
    bimg = rgba_from(np.clip(dval * 0.8, 0, 0.999), DIRT_PAL, 0.9)
    img[bank] = bimg[bank]
    height = np.where(stream, 0.0, height)
    # stepping stones across the stream where the path crosses
    # flowers
    rnd = random.Random(9)
    flower_cols = [hexc("#e0d060"), hexc("#d06080"), hexc("#a0a0f0"), hexc("#f0f0e0")]
    for _ in range(int(w * h / 900)):
        x, y = rnd.randrange(w), rnd.randrange(h)
        if not path[y, x] and not stream[y, x] and not bank[y, x]:
            c = rnd.choice(flower_cols)
            img[y, x, :3] = c
            if y + 1 < h:
                img[y + 1, x, :3] = GRASS_PAL[2]
    # grass blades
    for _ in range(int(w * h / 60)):
        x, y = rnd.randrange(1, w - 1), rnd.randrange(2, h)
        if not path[y, x] and not stream[y, x]:
            img[y - 1, x, :3] = GRASS_PAL[min(7, 5 + rnd.randrange(3))]
            img[y, x, :3] = GRASS_PAL[2]
    nm = normal_from_height(blur(height, 1), 2.5)
    return {"color": img, "normal": nm, "path_y": path_y, "stream_x": sx}


def tree_canopy(w: int, h: int, seed: int, palette: Sequence[RGB], trunk_h: int) -> Tuple[np.ndarray, np.ndarray]:
    """Round deciduous tree, origin at trunk base (bottom centre)."""
    img = new_img(w, h)
    height = np.zeros((h, w))
    rnd = random.Random(seed)
    cx = w / 2
    # trunk
    tw = max(4, w // 9)
    for y in range(h - trunk_h, h - 1):
        for x in range(int(cx - tw / 2), int(cx + tw / 2) + 1):
            t = (x - (cx - tw / 2)) / tw
            idx = int(np.clip((0.9 - t * 0.8) * len(BARK_PAL), 0, len(BARK_PAL) - 1))
            img[y, x] = (*BARK_PAL[idx], 255)
            height[y, x] = 0.6
    # roots
    for dx in (-tw, tw):
        for k in range(4):
            x = int(cx + dx * (0.5 + k * 0.2))
            y = h - 2 - k // 2
            if 0 <= x < w:
                img[y, x] = (*BARK_PAL[2], 255)
    # canopy made of clustered blobs
    ch = h - trunk_h + 6
    blobs = []
    for _ in range(14):
        bx = cx + rnd.uniform(-w * 0.32, w * 0.32)
        by = ch * 0.5 + rnd.uniform(-ch * 0.28, ch * 0.22)
        br = rnd.uniform(w * 0.14, w * 0.24)
        blobs.append((bx, by, br))
    n = value_noise(w, h, 4, seed, 2)
    for y in range(h):
        for x in range(w):
            best = -1.0
            for bx, by, br in blobs:
                d = ((x - bx) ** 2 + (y - by) ** 2) / (br * br)
                if d < 1.0:
                    best = max(best, 1 - d)
            if best > 0:
                # light from upper-left
                lv = 0.45 + (cx - x) / w * 0.5 + (ch * 0.5 - y) / ch * 0.45 + best * 0.3 + (n[y, x] - 0.5) * 0.35
                idx = int(np.clip(lv * len(palette), 0, len(palette) - 1))
                b = bayer(1, 1)
                img[y, x] = (*palette[idx], 255)
                height[y, x] = 0.4 + best
    # outline
    a = img[..., 3] > 0
    edge = ~a & (np.roll(a, 1, 0) | np.roll(a, -1, 0) | np.roll(a, 1, 1) | np.roll(a, -1, 1))
    img[edge] = (*palette[0], 255)
    nm = normal_from_height(blur(height, 1), 3.0, img[..., 3])
    return img, nm


def pine(w: int, h: int, seed: int, palette: Sequence[RGB] = LEAF_PAL) -> Tuple[np.ndarray, np.ndarray]:
    img = new_img(w, h)
    height = np.zeros((h, w))
    rnd = random.Random(seed)
    cx = w / 2
    trunk_h = h // 7
    for y in range(h - trunk_h - 2, h - 1):
        for x in range(int(cx - 2), int(cx + 2)):
            img[y, x] = (*BARK_PAL[2 if x < cx else 1], 255)
            height[y, x] = 0.5
    tiers = 5
    for t in range(tiers):
        ty0 = int(2 + t * (h - trunk_h - 4) / tiers * 0.9)
        ty1 = int(ty0 + (h - trunk_h) / tiers * 1.5)
        for y in range(ty0, min(ty1, h - trunk_h)):
            frac = (y - ty0) / max(1, ty1 - ty0)
            half = (w * 0.18 + t * w * 0.07) * frac + 1
            jag = rnd.uniform(-1.5, 1.5) if frac > 0.7 else 0
            for x in range(w):
                d = x - cx
                if abs(d) <= half + jag:
                    lv = 0.55 - d / w * 0.9 - frac * 0.25 + rnd.uniform(-0.08, 0.08)
                    idx = int(np.clip(lv * len(palette), 0, len(palette) - 1))
                    img[y, x] = (*palette[idx], 255)
                    height[y, x] = 1 - abs(d) / (half + 1) * 0.6
    a = img[..., 3] > 0
    edge = ~a & (np.roll(a, 1, 0) | np.roll(a, -1, 0) | np.roll(a, 1, 1) | np.roll(a, -1, 1))
    img[edge] = (*palette[0], 255)
    nm = normal_from_height(blur(height, 1), 3.0, img[..., 3])
    return img, nm


def bush(seed: int) -> np.ndarray:
    img, _ = tree_canopy(26, 18, seed, LEAF_PAL, 0)
    return img


def rock(w: int, h: int, seed: int) -> Tuple[np.ndarray, np.ndarray]:
    img = new_img(w, h)
    height = np.zeros((h, w))
    n = value_noise(w, h, 4, seed, 3)
    cx, cy = w / 2, h * 0.55
    for y in range(h):
        for x in range(w):
            dx = (x + 0.5 - cx) / (w / 2)
            dy = (y + 0.5 - cy) / (h * 0.5)
            d = dx * dx + dy * dy * 1.1 + (n[y, x] - 0.5) * 0.5
            if d < 1.0 and y < h - 1:
                lv = 0.6 - dx * 0.3 - dy * 0.35 + (n[y, x] - 0.5) * 0.3
                idx = int(np.clip(lv * 8, 1, 8))
                img[y, x] = (*ROCK_PAL[idx], 255)
                height[y, x] = 1 - d
    # moss on top
    for y in range(h):
        for x in range(w):
            if img[y, x, 3] and y < h * 0.4 and n[y, x] > 0.5:
                img[y, x, :3] = GRASS_PAL[4 if x < w / 2 else 3]
    a = img[..., 3] > 0
    edge = ~a & (np.roll(a, 1, 0) | np.roll(a, -1, 0) | np.roll(a, 1, 1) | np.roll(a, -1, 1))
    img[edge] = (*ROCK_PAL[0], 255)
    nm = normal_from_height(blur(height, 1), 3.0, img[..., 3])
    return img, nm


def log_prop() -> np.ndarray:
    s = MatSprite(30, 12)
    bark = s.m("bark", (BARK_PAL[1], BARK_PAL[3], BARK_PAL[4]))
    ring = s.m("ring", ramp("#5a3c22", "#8a6440", "#b08860"))
    s.rect(3, 3, 26, 9, bark)
    s.ellipse(27, 6, 3, 3.5, ring)
    s.px(27, 6, bark)
    s.ellipse(3, 6, 3, 3.5, bark)
    for x in range(6, 25, 4):
        s.px(x, 5, bark, 0)
    moss = s.m("moss", (GRASS_PAL[3], GRASS_PAL[5], GRASS_PAL[7]))
    s.hline(8, 14, 3, moss)
    return s.render()


def branch_pickup() -> np.ndarray:
    s = MatSprite(18, 10)
    bark = s.m("bark", (BARK_PAL[1], BARK_PAL[3], BARK_PAL[4]))
    s.line(1, 7, 16, 3, bark, width=2)
    s.line(8, 5, 11, 1, bark)
    leaf = s.m("leaf", (LEAF_PAL[3], LEAF_PAL[5], LEAF_PAL[7]))
    s.px(11, 0, leaf)
    s.px(12, 1, leaf)
    return s.render()


def stone_pickup() -> np.ndarray:
    s = MatSprite(14, 10)
    st = s.m("stone", (ROCK_PAL[3], ROCK_PAL[5], ROCK_PAL[7]))
    s.ellipse(6, 6, 5, 3.5, st)
    s.ellipse(10, 7, 3, 2.5, st)
    return s.render()


def herb_pickup() -> np.ndarray:
    s = MatSprite(14, 14)
    leaf = s.m("leaf", ramp("#1e3a1a", "#3e7a2a", "#7ab84e"))
    fl = s.m("flower", ramp("#6a2a7a", "#b060c0", "#e0a0f0"), flat=True)
    for (a, b, c, d) in ((7, 13, 3, 6), (7, 13, 11, 6), (7, 13, 7, 4)):
        s.line(a, b, c, d, leaf)
    s.ellipse(3, 6, 2, 1.5, leaf)
    s.ellipse(11, 6, 2, 1.5, leaf)
    s.rect(6, 2, 8, 4, fl)
    return s.render()


def campfire_frames() -> List[np.ndarray]:
    frames = []
    for f in range(5):
        s = MatSprite(24, 22)
        stone = s.m("stone", (ROCK_PAL[2], ROCK_PAL[4], ROCK_PAL[6]))
        wood = s.m("wood", (BARK_PAL[1], BARK_PAL[3], BARK_PAL[4]))
        for i in range(8):
            a = i / 8 * math.tau
            s.ellipse(12 + math.cos(a) * 9, 17 + math.sin(a) * 3.5, 2.2, 1.8, stone)
        s.line(6, 18, 17, 14, wood, width=2)
        s.line(17, 18, 7, 14, wood, width=2)
        img = s.render()
        if f > 0:
            fl = flame_frames()[(f - 1) % 4]
            big = fl.repeat(2, 0).repeat(2, 1)
            paste(img, big, 6, 1)
            ember = hexc("#ffd080")
            rnd = random.Random(f)
            for _ in range(3):
                x, y = rnd.randrange(6, 18), rnd.randrange(0, 6)
                img[y, x] = (*ember, 255)
        frames.append(img)
    return frames


def lean_to() -> np.ndarray:
    s = MatSprite(48, 34)
    wood = s.m("wood", (BARK_PAL[1], BARK_PAL[3], BARK_PAL[4]))
    leaf = s.m("thatch", (LEAF_PAL[2], LEAF_PAL[4], LEAF_PAL[6]))
    hide = s.m("hide", ramp("#3a2a1a", "#6a5034", "#8a7050"))
    s.line(4, 33, 22, 2, wood, width=2)
    s.line(44, 33, 26, 2, wood, width=2)
    s.line(18, 4, 30, 4, wood, width=2)
    s.poly([(22, 3), (27, 3), (46, 31), (16, 31)], leaf)
    for y in range(6, 31, 4):
        s.hline(18 + (31 - y) // 4, 44 - (31 - y) // 3, y, leaf, 0)
    s.poly([(6, 31), (16, 31), (20, 22), (12, 22)], hide)
    return s.render()


def bedroll() -> np.ndarray:
    s = MatSprite(26, 12)
    cloth = s.m("cloth", ramp("#2a2440", "#463e66", "#6a5e8e"))
    straw = s.m("straw", ramp("#6a5020", "#a88440", "#d8b460"))
    s.rect(2, 3, 23, 9, straw)
    s.rect(8, 2, 23, 9, cloth)
    return s.render()


def wanted_post() -> np.ndarray:
    s = MatSprite(24, 40)
    wood = s.m("wood", (BARK_PAL[1], BARK_PAL[3], BARK_PAL[4]))
    paper = s.m("paper", ramp("#8a7a5a", "#d8c8a0", "#f4e8c8"))
    ink = s.m("ink", ramp("#1a1010", "#3a2420", "#5a3a30"), flat=True)
    red = s.m("red", ramp("#5a0a10", "#a01828", "#d04050"), flat=True)
    s.rect(10, 6, 13, 39, wood)
    s.rect(2, 8, 21, 27, paper)
    s.hline(4, 19, 10, red)
    # crude portrait (very unflattering, as the Scholar notes)
    s.ellipse(11.5, 17, 4.5, 4.5, ink)
    s.ellipse(11.5, 17.5, 3, 3, paper)
    s.rect(9, 17, 14, 18, ink)  # enormous nose
    s.hline(4, 19, 24, ink)
    s.hline(6, 17, 26, ink)
    s.px(3, 9, wood)
    s.px(20, 9, wood)
    return s.render()


def house(seed: int, roof: str = "thatch") -> Tuple[np.ndarray, np.ndarray]:
    w, h = 72, 64
    s = MatSprite(w, h)
    wall = s.m("wall", ramp("#5a4a3a", "#9a8668", "#c8b08a"))
    beam = s.m("beam", (BARK_PAL[1], BARK_PAL[2], BARK_PAL[3]))
    if roof == "thatch":
        rf = s.m("roof", ramp("#4a3a1a", "#7a6430", "#a88a48"))
    else:
        rf = s.m("roof", ramp("#3a1a1a", "#6a2a26", "#9a4038"))
    door = s.m("door", (BARK_PAL[0], BARK_PAL[2], BARK_PAL[3]))
    win = s.m("window", ramp("#c06010", "#ffb040", "#fff0b0"), flat=True, emissive=True)
    stone = s.m("stone", (ROCK_PAL[3], ROCK_PAL[5], ROCK_PAL[7]))
    s.rect(8, 30, 63, 61, wall)
    s.rect(8, 56, 63, 62, stone)
    for x in (8, 26, 45, 63):
        s.vline(x, 30, 56, beam)
    s.hline(8, 63, 42, beam)
    s.poly([(2, 32), (36, 4), (70, 32)], rf)
    for y in range(10, 32, 4):
        for x in range(4, 69):
            if int(s.mat[y, x]) == rf and (x + y) % 5 == 0:
                s.px(x, y, rf, 0)
    # chimney
    s.rect(50, 8, 56, 22, stone)
    s.rect(30, 46, 40, 61, door)
    s.px(38, 54, s.m("knob", ramp("#6a4414", "#c8902a", "#f8d870")))
    s.rect(14, 46, 21, 52, win)
    s.rect(50, 46, 57, 52, win)
    s.vline(17, 46, 52, beam)
    s.vline(53, 46, 52, beam)
    img = s.render()
    return img, s.emissive_mask()


def fence() -> np.ndarray:
    s = MatSprite(32, 16)
    wood = s.m("wood", (BARK_PAL[1], BARK_PAL[3], BARK_PAL[4]))
    for x in (2, 15, 28):
        s.rect(x, 2, x + 1, 15, wood)
    s.hline(1, 31, 5, wood)
    s.hline(1, 31, 10, wood)
    return s.render()


def lamp_post() -> Tuple[np.ndarray, np.ndarray]:
    s = MatSprite(14, 40)
    wood = s.m("wood", (BARK_PAL[1], BARK_PAL[3], BARK_PAL[4]))
    iron = s.m("iron", ramp("#14121a", "#2e2c36", "#4e4c5a"))
    glass = s.m("glass", ramp("#c06010", "#ffb040", "#fff0b0"), flat=True, emissive=True)
    s.rect(6, 8, 7, 39, wood)
    s.hline(7, 11, 8, wood)
    s.rect(9, 9, 13, 16, iron)
    s.rect(10, 10, 12, 15, glass)
    return s.render(), s.emissive_mask()


def well() -> np.ndarray:
    s = MatSprite(32, 34)
    stone = s.m("stone", (ROCK_PAL[3], ROCK_PAL[5], ROCK_PAL[7]))
    wood = s.m("wood", (BARK_PAL[1], BARK_PAL[3], BARK_PAL[4]))
    roof = s.m("roof", ramp("#3a1a1a", "#6a2a26", "#9a4038"))
    water = s.m("water", (WATER_PAL[1], WATER_PAL[2], WATER_PAL[3]))
    s.ellipse(16, 26, 13, 7, stone)
    s.ellipse(16, 24, 10, 4, water)
    s.rect(4, 6, 5, 26, wood)
    s.rect(26, 6, 27, 26, wood)
    s.poly([(1, 8), (16, 1), (31, 8)], roof)
    s.hline(5, 26, 12, wood)
    return s.render()


# ---------------------------------------------------------------------------
# Battle background: mountain forest path at night
# ---------------------------------------------------------------------------
NIGHT_SKY = pal("#04040a", "#080814", "#0e0e20", "#16162e", "#20203e")
NIGHT_TREES = [pal("#06080c", "#0a0e14", "#0e141a"), pal("#080c10", "#0e1418", "#141c20", "#1a2428"),
               pal("#0a1012", "#10181a", "#162224", "#1e2c2c", "#283a36")]


def battle_forest(w: int = 480, h: int = 270) -> Dict[str, np.ndarray]:
    img = new_img(w, h)
    yy, xx = np.mgrid[0:h, 0:w]
    sky = rgba_from(np.clip(0.9 - yy / h * 1.2 + value_noise(w, h, 30, 301, 3) * 0.2, 0, 0.999), NIGHT_SKY, 0.8)
    img[:] = sky
    # moon
    mx, my = 360, 46
    d = np.hypot(xx - mx, yy - my)
    halo = np.clip(1 - d / 70, 0, 1) ** 2
    img[..., :3] = np.clip(img[..., :3] + (halo[..., None] * np.array([60, 70, 90])), 0, 255).astype(np.uint8)
    img[d < 14] = (*hexc("#e8eaf4"), 255)
    img[(d < 14) & (value_noise(w, h, 3, 309, 2) > 0.6)] = (*hexc("#b8bccc"), 255)
    # distant mountains
    mnt = mountains_layer(w, 150, 310, 40, 0.55, pal("#121228", "#1a1c34", "#232842", "#2e3550"), snow=True)
    paste(img, mnt, 0, 40)
    # low mist band
    mist = np.clip(1 - np.abs(yy - 150) / 40.0, 0, 1) * (0.5 + value_noise(w, h, 40, 311, 3) * 0.5)
    img[..., :3] = np.clip(img[..., :3] + mist[..., None] * np.array([18, 20, 34]), 0, 255).astype(np.uint8)
    # tree silhouettes, three layers
    for li, (pal_l, base, seed) in enumerate(zip(NIGHT_TREES, (150, 175, 200), (302, 303, 304))):
        rnd = random.Random(seed)
        layer = new_img(w, h)
        x = -10 + li * 9
        while x < w + 10:
            tw = rnd.randint(14, 24) + li * 6
            th = rnd.randint(50, 90) + li * 26
            if li < 2 and 170 < x < 310 and rnd.random() < 0.7:
                x += rnd.randint(30, 50)
                continue
            base_y = base + rnd.randint(-8, 8) + li * 20
            for y in range(max(0, base_y - th), min(h, base_y + 80)):
                frac = (y - (base_y - th)) / th
                half = max(1, tw * min(frac, 1.0) * 0.6 + (1 if y % 6 < 3 else -1))
                for xx2 in range(int(x - half), int(x + half) + 1):
                    if 0 <= xx2 < w:
                        k = 1 if xx2 > x else 0
                        if li == 2 and xx2 < x - half + 2:
                            k = 2
                        layer[y, xx2] = (*pal_l[min(k, len(pal_l) - 1)], 255)
            x += rnd.randint(26, 48) + li * 6
        paste(img, layer, 0, 0)
    # ground and path
    gy = 200
    n = value_noise(w, h - gy, 10, 305, 3)
    ground = rgba_from(np.clip(0.2 + n * 0.4 + np.linspace(0, 0.25, h - gy)[:, None], 0, 0.999),
                       pal("#06080a", "#0c1012", "#121a18", "#1a2420", "#22302a", "#2c3c32"), 0.8)
    img[gy:] = ground
    path = np.abs(xx[gy:] - w / 2 + np.sin(yy[gy:] / 14.0) * 6) < 26 + (yy[gy:] - gy) * 1.6
    pimg = rgba_from(np.clip(0.25 + n * 0.4 + np.linspace(0, 0.3, h - gy)[:, None], 0, 0.999),
                     pal("#0e0c0c", "#18140f", "#221c16", "#2e261c", "#3a3022"), 0.8)
    img[gy:][path] = pimg[path]
    # fireflies / will-o-wisps baked as tiny dots (animated ones are particles in-engine)
    return {"color": img}


# ---------------------------------------------------------------------------
# Synod chamber (epilogue)
# ---------------------------------------------------------------------------
def synod_chamber() -> Dict[str, np.ndarray]:
    W, H = 427, 240
    img = new_img(W, H)
    height = np.zeros((H, W))
    emi = new_img(W, H)
    wv, wh = brick_surface(W, 130, 20, 10, 401)
    img[:130] = rgba_from(wv * 0.8, STONE_PAL)
    height[:130] = wh * 0.6
    fv, fh = tile_floor(W, H - 130, 30, 16, 402)
    img[130:] = rgba_from(fv * 0.75, MARBLE_PAL)
    height[130:] = fh * 0.5
    # tall bookshelves
    for bx in (20, 330):
        img[20:130, bx:bx + 76, :3] = WOOD_PAL[1]
        for sy in range(28, 128, 20):
            img[sy:sy + 2, bx + 2:bx + 74, :3] = WOOD_PAL[3]
            rnd = random.Random(bx + sy)
            x = bx + 4
            while x < bx + 70:
                bw = rnd.randint(2, 5)
                bh = rnd.randint(12, 17)
                col = rnd.choice([hexc("#4a1a1a"), hexc("#1a2a4a"), hexc("#2a3a1a"), hexc("#4a3a1a"),
                                  hexc("#3a1a3a")])
                img[sy - bh:sy, x:x + bw, :3] = col
                img[sy - bh:sy, x, :3] = mix(col, (255, 255, 255), 0.15)
                x += bw + 1
        height[20:130, bx:bx + 76] = 0.8
    # tall window with moonlight
    wimg, wemi = stained_window(46, 92, 404, "eye")
    # darken it: night
    wimg[..., :3] = (wimg[..., :3] * 0.55).astype(np.uint8)
    wemi[..., :3] = (wemi[..., :3] * 0.5).astype(np.uint8)
    paste(img, wimg, 190, 20)
    paste(emi, wemi, 190, 20)
    nm = normal_from_height(blur(height, 1), 3.0)
    return {"color": img, "normal": nm, "emissive": emi}


def desk() -> np.ndarray:
    s = MatSprite(96, 40)
    wood = s.m("wood", (WOOD_PAL[1], WOOD_PAL[3], WOOD_PAL[4]))
    top = s.m("top", (WOOD_PAL[2], WOOD_PAL[3], hexc("#7a5034")))
    gold = s.m("gold", ramp("#6a4414", "#c8902a", "#f8d870"))
    paper = s.m("paper", ramp("#8a7a5a", "#d8c8a0", "#f4e8c8"))
    s.rect(2, 10, 93, 16, top)
    s.rect(4, 17, 91, 38, wood)
    s.hline(4, 91, 17, gold)
    for x in (10, 48, 84):
        s.rect(x - 1, 22, x + 1, 33, wood, 0)
    s.rect(30, 5, 50, 10, paper)
    s.rect(58, 4, 72, 10, paper)
    return s.render()
