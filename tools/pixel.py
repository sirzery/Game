"""Small pixel-art toolkit used by gen_art.py.

Everything is drawn into numpy arrays and saved as PNG through Pillow, so the
whole art set of DOSIER can be regenerated deterministically:

    python3 tools/gen_art.py

The sprites are built from flat "material" regions which are then cel-shaded
(light from the upper-left, like most HD-2D sprites), outlined with a
selective dark outline, and optionally given an auto-generated normal map so
Godot's 2D lights can light them with depth.
"""
from __future__ import annotations

import math
import os
from typing import Dict, Iterable, List, Optional, Sequence, Tuple

import numpy as np
from PIL import Image

RGB = Tuple[int, int, int]
Ramp = Tuple[RGB, RGB, RGB]  # (shadow, base, light)

OUTLINE = (20, 12, 22)


def hexc(h: str) -> RGB:
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def ramp(shadow: str, base: str, light: str) -> Ramp:
    return (hexc(shadow), hexc(base), hexc(light))


def mix(a: Sequence[float], b: Sequence[float], t: float) -> RGB:
    return (
        int(round(a[0] + (b[0] - a[0]) * t)),
        int(round(a[1] + (b[1] - a[1]) * t)),
        int(round(a[2] + (b[2] - a[2]) * t)),
    )


def darken(c: Sequence[float], t: float) -> RGB:
    return mix(c, OUTLINE, t)


# ---------------------------------------------------------------------------
# Material sprite
# ---------------------------------------------------------------------------
class MatSprite:
    """A sprite made of material ids. 0 = transparent."""

    def __init__(self, w: int, h: int):
        self.w = w
        self.h = h
        self.mat = np.zeros((h, w), np.int16)
        self.tone = np.full((h, w), -1, np.int8)  # -1 auto, 0 shadow, 1 base, 2 light, 3 extra-dark
        self.ramps: Dict[int, Ramp] = {}
        self.flat: set = set()
        self.emissive: set = set()
        self.no_outline: set = set()
        self._next = 1
        self._by_name: Dict[str, int] = {}

    # -- materials ---------------------------------------------------------
    def m(self, name: str, r: Ramp, flat: bool = False, emissive: bool = False,
          no_outline: bool = False) -> int:
        if name in self._by_name:
            return self._by_name[name]
        mid = self._next
        self._next += 1
        self._by_name[name] = mid
        self.ramps[mid] = r
        if flat:
            self.flat.add(mid)
        if emissive:
            self.emissive.add(mid)
        if no_outline:
            self.no_outline.add(mid)
        return mid

    # -- primitives --------------------------------------------------------
    def px(self, x: int, y: int, mid: int, tone: int = -1) -> None:
        if 0 <= x < self.w and 0 <= y < self.h:
            self.mat[y, x] = mid
            self.tone[y, x] = tone

    def erase(self, x: int, y: int) -> None:
        if 0 <= x < self.w and 0 <= y < self.h:
            self.mat[y, x] = 0
            self.tone[y, x] = -1

    def rect(self, x0: int, y0: int, x1: int, y1: int, mid: int, tone: int = -1) -> None:
        """Inclusive rectangle."""
        for y in range(min(y0, y1), max(y0, y1) + 1):
            for x in range(min(x0, x1), max(x0, x1) + 1):
                self.px(x, y, mid, tone)

    def hline(self, x0: int, x1: int, y: int, mid: int, tone: int = -1) -> None:
        self.rect(x0, y, x1, y, mid, tone)

    def vline(self, x: int, y0: int, y1: int, mid: int, tone: int = -1) -> None:
        self.rect(x, y0, x, y1, mid, tone)

    def ellipse(self, cx: float, cy: float, rx: float, ry: float, mid: int, tone: int = -1) -> None:
        for y in range(int(cy - ry - 1), int(cy + ry + 2)):
            for x in range(int(cx - rx - 1), int(cx + rx + 2)):
                dx = (x + 0.5 - cx) / max(rx, 0.01)
                dy = (y + 0.5 - cy) / max(ry, 0.01)
                if dx * dx + dy * dy <= 1.0:
                    self.px(x, y, mid, tone)

    def poly(self, pts: Sequence[Tuple[float, float]], mid: int, tone: int = -1) -> None:
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        for y in range(int(min(ys)), int(max(ys)) + 1):
            for x in range(int(min(xs)), int(max(xs)) + 1):
                if point_in_poly(x + 0.5, y + 0.5, pts):
                    self.px(x, y, mid, tone)

    def line(self, x0: float, y0: float, x1: float, y1: float, mid: int, tone: int = -1,
             width: int = 1) -> None:
        steps = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for i in range(steps + 1):
            t = i / max(steps, 1)
            x = x0 + (x1 - x0) * t
            y = y0 + (y1 - y0) * t
            if width <= 1:
                self.px(int(round(x)), int(round(y)), mid, tone)
            else:
                r = width / 2.0
                self.ellipse(x + 0.5, y + 0.5, r, r, mid, tone)

    def blit(self, other: "MatSprite", ox: int, oy: int, flip: bool = False) -> None:
        """Copy another MatSprite on top (materials are remapped by name)."""
        remap = {}
        for name, mid in other._by_name.items():
            mid2 = self.m(name, other.ramps[mid], mid in other.flat, mid in other.emissive,
                          mid in other.no_outline)
            remap[mid] = mid2
        for y in range(other.h):
            for x in range(other.w):
                sx = other.w - 1 - x if flip else x
                mm = other.mat[y, sx]
                if mm:
                    self.px(ox + x, oy + y, remap[int(mm)], int(other.tone[y, sx]))

    def flipped(self) -> "MatSprite":
        s = MatSprite(self.w, self.h)
        s.ramps = dict(self.ramps)
        s.flat = set(self.flat)
        s.emissive = set(self.emissive)
        s.no_outline = set(self.no_outline)
        s._next = self._next
        s._by_name = dict(self._by_name)
        s.mat = self.mat[:, ::-1].copy()
        s.tone = self.tone[:, ::-1].copy()
        return s

    # -- rendering ---------------------------------------------------------
    def render(self, outline: bool = True, light_from_right: bool = False) -> np.ndarray:
        h, w = self.h, self.w
        out = np.zeros((h, w, 4), np.uint8)
        mat = self.mat
        lx = 1 if light_from_right else -1  # direction towards the light on x
        for y in range(h):
            for x in range(w):
                mm = int(mat[y, x])
                if not mm:
                    continue
                r = self.ramps[mm]
                t = int(self.tone[y, x])
                if t < 0:
                    if mm in self.flat:
                        t = 1
                    else:
                        def same(xx: int, yy: int) -> bool:
                            return 0 <= xx < w and 0 <= yy < h and int(mat[yy, xx]) == mm
                        lit = (not same(x + lx, y)) or (not same(x, y - 1))
                        dark = (not same(x - lx, y)) or (not same(x, y + 1)) or (not same(x - 2 * lx, y))
                        if dark and not lit:
                            t = 0
                        elif lit and not dark:
                            t = 2
                        elif lit and dark:
                            t = 1
                        else:
                            t = 1
                if t == 3:
                    c = darken(r[0], 0.45)
                else:
                    c = r[max(0, min(2, t))]
                out[y, x, :3] = c
                out[y, x, 3] = 255
        if outline:
            src = out.copy()
            for y in range(h):
                for x in range(w):
                    if src[y, x, 3]:
                        continue
                    best = None
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        xx, yy = x + dx, y + dy
                        if 0 <= xx < w and 0 <= yy < h and src[yy, xx, 3]:
                            mm = int(mat[yy, xx])
                            if mm in self.no_outline:
                                continue
                            best = mm
                            break
                    if best is not None:
                        out[y, x, :3] = darken(self.ramps[best][0], 0.72)
                        out[y, x, 3] = 255
        return out

    def emissive_mask(self) -> np.ndarray:
        """RGBA image containing only the emissive materials (for glow layers)."""
        out = np.zeros((self.h, self.w, 4), np.uint8)
        for y in range(self.h):
            for x in range(self.w):
                mm = int(self.mat[y, x])
                if mm in self.emissive:
                    out[y, x, :3] = self.ramps[mm][2]
                    out[y, x, 3] = 255
        return out


def point_in_poly(x: float, y: float, pts: Sequence[Tuple[float, float]]) -> bool:
    inside = False
    n = len(pts)
    j = n - 1
    for i in range(n):
        xi, yi = pts[i]
        xj, yj = pts[j]
        if ((yi > y) != (yj > y)) and (x < (xj - xi) * (y - yi) / ((yj - yi) or 1e-9) + xi):
            inside = not inside
        j = i
    return inside


# ---------------------------------------------------------------------------
# Image helpers (numpy RGBA arrays)
# ---------------------------------------------------------------------------
def new_img(w: int, h: int) -> np.ndarray:
    return np.zeros((h, w, 4), np.uint8)


def paste(dst: np.ndarray, src: np.ndarray, ox: int, oy: int) -> None:
    """Alpha-composite src onto dst at (ox, oy) (binary alpha friendly)."""
    h, w = src.shape[:2]
    H, W = dst.shape[:2]
    x0, y0 = max(0, ox), max(0, oy)
    x1, y1 = min(W, ox + w), min(H, oy + h)
    if x0 >= x1 or y0 >= y1:
        return
    s = src[y0 - oy:y1 - oy, x0 - ox:x1 - ox].astype(np.float32)
    d = dst[y0:y1, x0:x1].astype(np.float32)
    a = s[..., 3:4] / 255.0
    da = d[..., 3:4] / 255.0
    out_a = a + da * (1 - a)
    rgb = (s[..., :3] * a + d[..., :3] * da * (1 - a)) / np.maximum(out_a, 1e-6)
    d[..., :3] = rgb
    d[..., 3:4] = out_a * 255.0
    dst[y0:y1, x0:x1] = np.clip(d + 0.5, 0, 255).astype(np.uint8)


def save(img: np.ndarray, path: str) -> None:
    d = os.path.dirname(path)
    if d:
        os.makedirs(d, exist_ok=True)
    Image.fromarray(img, "RGBA").save(path, optimize=True)


def sheet(frames: List[List[np.ndarray]]) -> np.ndarray:
    """Rows of equally sized frames -> single sprite sheet."""
    fh, fw = frames[0][0].shape[:2]
    rows = len(frames)
    cols = max(len(r) for r in frames)
    out = new_img(fw * cols, fh * rows)
    for j, row in enumerate(frames):
        for i, f in enumerate(row):
            out[j * fh:(j + 1) * fh, i * fw:(i + 1) * fw] = f
    return out


def upscale(img: np.ndarray, k: int) -> np.ndarray:
    return img.repeat(k, axis=0).repeat(k, axis=1)


# ---------------------------------------------------------------------------
# Noise & dithering
# ---------------------------------------------------------------------------
def value_noise(w: int, h: int, scale: float, seed: int, octaves: int = 4,
                persistence: float = 0.5) -> np.ndarray:
    rng = np.random.default_rng(seed)
    total = np.zeros((h, w), np.float64)
    amp = 1.0
    norm = 0.0
    for o in range(octaves):
        gs = max(1.0, scale / (2 ** o))
        gw = int(w / gs) + 3
        gh = int(h / gs) + 3
        grid = rng.random((gh, gw))
        ys = np.arange(h) / gs
        xs = np.arange(w) / gs
        y0 = ys.astype(int)
        x0 = xs.astype(int)
        fy = ys - y0
        fx = xs - x0
        fy = fy * fy * (3 - 2 * fy)
        fx = fx * fx * (3 - 2 * fx)
        a = grid[y0][:, x0]
        b = grid[y0][:, x0 + 1]
        c = grid[y0 + 1][:, x0]
        d = grid[y0 + 1][:, x0 + 1]
        top = a * (1 - fx) + b * fx
        bot = c * (1 - fx) + d * fx
        n = top * (1 - fy[:, None]) + bot * fy[:, None]
        total += n * amp
        norm += amp
        amp *= persistence
    return total / norm


BAYER4 = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]], np.float64) / 16.0


def bayer(w: int, h: int) -> np.ndarray:
    reps = (h // 4 + 1, w // 4 + 1)
    return np.tile(BAYER4, reps)[:h, :w]


def quantize(values: np.ndarray, palette: Sequence[RGB], dither: float = 0.6) -> np.ndarray:
    """Map values in [0,1] onto a palette ramp with ordered dithering."""
    h, w = values.shape
    n = len(palette)
    b = bayer(w, h) - 0.5
    idx = np.clip(np.floor(values * n + b * dither), 0, n - 1).astype(int)
    pal = np.array(palette, np.uint8)
    out = np.zeros((h, w, 4), np.uint8)
    out[..., :3] = pal[idx]
    out[..., 3] = 255
    return out


# ---------------------------------------------------------------------------
# Normal maps
# ---------------------------------------------------------------------------
def distance_inside(alpha: np.ndarray, max_d: int = 8) -> np.ndarray:
    """Approximate distance to the outside of the opaque area (chessboard)."""
    inside = alpha > 0
    d = np.where(inside, max_d, 0).astype(np.float64)
    h, w = alpha.shape
    # two-pass chamfer
    for y in range(h):
        for x in range(w):
            if inside[y, x]:
                v = d[y, x]
                if x > 0:
                    v = min(v, d[y, x - 1] + 1)
                else:
                    v = min(v, 1)
                if y > 0:
                    v = min(v, d[y - 1, x] + 1)
                else:
                    v = min(v, 1)
                d[y, x] = v
    for y in range(h - 1, -1, -1):
        for x in range(w - 1, -1, -1):
            if inside[y, x]:
                v = d[y, x]
                if x < w - 1:
                    v = min(v, d[y, x + 1] + 1)
                else:
                    v = min(v, 1)
                if y < h - 1:
                    v = min(v, d[y + 1, x] + 1)
                else:
                    v = min(v, 1)
                d[y, x] = v
    return d


def blur(a: np.ndarray, r: int = 1) -> np.ndarray:
    out = a.copy()
    for _ in range(r):
        p = np.pad(out, 1, mode="edge")
        out = (p[:-2, 1:-1] + p[2:, 1:-1] + p[1:-1, :-2] + p[1:-1, 2:] + p[1:-1, 1:-1] * 2) / 6.0
    return out


def normal_from_height(height: np.ndarray, strength: float = 2.0,
                       alpha: Optional[np.ndarray] = None) -> np.ndarray:
    """OpenGL convention (green = up) as expected by Godot."""
    gy, gx = np.gradient(height)
    nx = -gx * strength
    ny = gy * strength  # image y grows downwards -> flip for Y-up
    nz = np.ones_like(height)
    ln = np.sqrt(nx * nx + ny * ny + nz * nz)
    nx, ny, nz = nx / ln, ny / ln, nz / ln
    out = np.zeros(height.shape + (4,), np.uint8)
    out[..., 0] = np.clip((nx * 0.5 + 0.5) * 255, 0, 255)
    out[..., 1] = np.clip((ny * 0.5 + 0.5) * 255, 0, 255)
    out[..., 2] = np.clip((nz * 0.5 + 0.5) * 255, 0, 255)
    out[..., 3] = 255 if alpha is None else alpha
    return out


def sprite_normal(img: np.ndarray, depth: int = 6, strength: float = 1.2,
                  detail: float = 0.35) -> np.ndarray:
    """Pillow-like normal map from the silhouette plus luminance detail."""
    alpha = img[..., 3]
    d = distance_inside(alpha, depth)
    hgt = np.sqrt(np.clip(d / depth, 0, 1))
    lum = (img[..., 0] * 0.3 + img[..., 1] * 0.59 + img[..., 2] * 0.11) / 255.0
    hgt = blur(hgt, 1) + lum * detail
    n = normal_from_height(hgt, strength * 3.0, alpha)
    n[alpha == 0] = (128, 128, 255, 0)
    return n


def sheet_normal(img: np.ndarray, fw: int, fh: int, **kw) -> np.ndarray:
    out = np.zeros_like(img)
    H, W = img.shape[:2]
    for y in range(0, H, fh):
        for x in range(0, W, fw):
            out[y:y + fh, x:x + fw] = sprite_normal(img[y:y + fh, x:x + fw], **kw)
    return out


def rgba(c: RGB, a: int = 255) -> Tuple[int, int, int, int]:
    return (c[0], c[1], c[2], a)


def fill_alpha_where(img: np.ndarray, mask: np.ndarray, color: RGB, a: int = 255) -> None:
    img[mask, 0] = color[0]
    img[mask, 1] = color[1]
    img[mask, 2] = color[2]
    img[mask, 3] = a


def clamp01(a: np.ndarray) -> np.ndarray:
    return np.clip(a, 0.0, 1.0)


def lerp_palette(stops: Sequence[RGB], n: int) -> List[RGB]:
    """Interpolate a list of colour stops into n palette entries."""
    out = []
    for i in range(n):
        t = i / max(n - 1, 1) * (len(stops) - 1)
        k = min(int(t), len(stops) - 2)
        out.append(mix(stops[k], stops[k + 1], t - k))
    return out


def iter_grid(w: int, h: int) -> Iterable[Tuple[int, int]]:
    for y in range(h):
        for x in range(w):
            yield x, y


def angle_deg(a: float) -> float:
    return math.radians(a)
