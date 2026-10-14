#!/usr/bin/env python3
"""Generates every sprite / background / portrait of DOSIER into assets/sprites.

Run from the project root:   python3 tools/gen_art.py
Requires: numpy, pillow.
"""
from __future__ import annotations

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import numpy as np  # noqa: E402

import art_creatures as cr  # noqa: E402
import art_env as env  # noqa: E402
import art_portraits as pt  # noqa: E402
from art_humanoid import frame, pose_battle, pose_burden, pose_kneel, pose_kneel_back  # noqa: E402
from pixel import (MatSprite, hexc, new_img, paste, ramp, save, sheet, sheet_normal,  # noqa: E402
                   sprite_normal)

ROOT = os.path.normpath(os.path.join(HERE, ".."))
OUT = os.path.join(ROOT, "assets", "sprites")


def out(*parts: str) -> str:
    return os.path.join(OUT, *parts)


# ---------------------------------------------------------------------------
# Character specs (sprite + portrait share the palette)
# ---------------------------------------------------------------------------
SKIN_MC = ramp("#a0604c", "#dca27c", "#f4cca4")
MC = {
    "skin": SKIN_MC,
    "hair": ramp("#1a1220", "#33242e", "#54404a"),
    "hair_style": "messy",
    "top": ramp("#3e352e", "#6b5c4c", "#93806a"),
    "legs": ramp("#2a2630", "#45404c", "#625a68"),
    "sash": ramp("#1c2240", "#2e3a6a", "#4a5c9a"),
    "cuffs": True,
    "eye": ramp("#141020", "#2a3050", "#4a5880"),
}
COIF = ramp("#6a6a80", "#a8a6b0", "#d0ccd4")
COUNCIL = {
    "skin": ramp("#8a6a5a", "#c8a890", "#e8d0b8"), "masked": True, "mask": ramp("#7a5418", "#c8902a", "#f8d870"),
    "top_style": "robe", "top": ramp("#8a8aa0", "#d0ccc4", "#f4f0e8"), "trim": ramp("#7a5418", "#c8902a", "#f8d870"),
    "hat": "mitre", "hat_col": ramp("#8a8aa0", "#d8d4cc", "#fffaf0"), "feet": ramp("#3a2a20", "#5a4030", "#7a5a40"),
    "hair_style": "none", "coif": COIF,
}
ARBITER = dict(COUNCIL)
ARBITER.update({
    "top": ramp("#2a0610", "#6a1020", "#a02032"), "hat_col": ramp("#2a0610", "#6a1020", "#a02032"),
    "stole": ramp("#7a5418", "#c8902a", "#f8d870"), "mask": ramp("#4a4a58", "#9a9aac", "#dcdcec"),
    "coif": ramp("#2a0610", "#4a0c18", "#6a1020"),
})
SAINT = {
    "skin": ramp("#b07a68", "#ecc4a8", "#fde4cc"), "hair": ramp("#8a90b0", "#d0d6ee", "#ffffff"),
    "hair_style": "silver_long", "top_style": "long_robe", "top": ramp("#9a9cb8", "#e4e6f4", "#ffffff"),
    "trim": ramp("#8a6418", "#e0b040", "#fff0a0"), "cape": ramp("#6a5010", "#c89a30", "#f8d870"),
    "hat": "halo", "hat_col": ramp("#c09030", "#ffe890", "#fffff0"), "feet": ramp("#7a6a40", "#c8b070", "#f0e0a0"),
    "eye": ramp("#806010", "#f0c020", "#fff0a0"),
}
GUARD = {
    "skin": ramp("#8a5a48", "#c89070", "#e8b898"), "top_style": "armor", "top": ramp("#30323c", "#6a6e7e", "#a8acbc"),
    "trim": ramp("#5a0a14", "#a01828", "#d04050"), "tabard": ramp("#b8b0a0", "#e8e0d0", "#fffaf0"),
    "hat": "helm", "hat_col": ramp("#30323c", "#7a7e8e", "#c0c4d4"), "legs": ramp("#20222a", "#3e404c", "#5a5c6a"),
    "feet": ramp("#1a1414", "#3a2a24", "#5a4034"), "plume": ramp("#5a0a14", "#a01828", "#d04050"),
    "hair_style": "none",
}
MAREN = {
    "skin": ramp("#a8705a", "#e6b494", "#fad4b8"), "hair": ramp("#4a1e14", "#7e3a22", "#b45e36"),
    "hair_style": "braid", "top_style": "dress", "top": ramp("#22402c", "#3e6a46", "#68985e"),
    "bodice": ramp("#3a2418", "#6a4630", "#9a6c48"), "apron": ramp("#a89c84", "#e0d6c0", "#fbf6e8"),
    "feet": ramp("#2a1c14", "#4a3424", "#6a4c34"), "eye": ramp("#1a2a14", "#3a6a2a", "#6aa04a"),
}
HUNTER = {
    "skin": ramp("#8a5a48", "#c08a6a", "#e0aa88"), "hair_style": "none", "top_style": "robe",
    "top": ramp("#14141a", "#24242e", "#383844"), "trim": ramp("#3a0a10", "#6a1420", "#9a2030"),
    "hat": "hood", "hat_col": ramp("#0e0e14", "#1c1c26", "#2c2c38"), "feet": ramp("#1a1414", "#2a2420", "#3a302a"),
    "eye": ramp("#6a4010", "#d89020", "#ffd060"),
}

PORTRAITS = {
    "mc": ({"skin": SKIN_MC, "hair": MC["hair"], "hair_style": "messy", "cloth": MC["top"], "collar": "scholar",
            "iris": ramp("#1a2440", "#3a5a8a", "#8ab0e0"), "scar": True, "sweat": True},
           ["neutral", "angry", "smirk", "pain", "surprised", "closed", "sad"]),
    "arbiter": ({"skin": ARBITER["skin"], "masked": True, "mask": ARBITER["mask"], "cloth": ARBITER["top"],
                 "trim": ARBITER["stole"], "collar": "robe", "hat": "mitre", "hat_col": ARBITER["hat_col"]},
                ["neutral"]),
    "council": ({"skin": COUNCIL["skin"], "masked": True, "mask": COUNCIL["mask"], "cloth": COUNCIL["top"],
                 "trim": COUNCIL["trim"], "collar": "robe", "hat": "mitre", "hat_col": COUNCIL["hat_col"]},
                ["neutral"]),
    "saint": ({"skin": SAINT["skin"], "hair": SAINT["hair"], "hair_style": "silver_long", "cloth": SAINT["top"],
               "trim": SAINT["trim"], "collar": "armor", "hat": "halo", "iris": ramp("#806010", "#f0c020", "#fff0a0")},
              ["neutral", "angry", "closed", "surprised"]),
    "maren": ({"skin": MAREN["skin"], "hair": MAREN["hair"], "hair_style": "braid", "cloth": MAREN["top"],
               "trim": MAREN["bodice"], "collar": "dress", "iris": ramp("#1a3a14", "#3a7a2a", "#7ac04a"),
               "freckles": True},
              ["neutral", "angry", "surprised", "smile", "flustered", "sad", "closed"]),
    "exiled": ({"skin": cr.FUR, "shadowed": True, "cloth": cr.FUR, "horns": True}, ["neutral"]),
    "hunter": ({"skin": HUNTER["skin"], "hair": ramp("#101014", "#20202a", "#34343e"), "hair_style": "short",
                "cloth": HUNTER["top"], "trim": HUNTER["trim"], "collar": "hunter", "hood": HUNTER["hat_col"],
                "scarf": HUNTER["trim"], "iris": HUNTER["eye"]}, ["neutral", "angry", "closed"]),
    "guard": ({"skin": GUARD["skin"], "cloth": GUARD["top"], "trim": GUARD["trim"], "collar": "armor",
               "hat": "helm", "hat_col": GUARD["hat_col"]}, ["neutral"]),
}


def walk_sheet(spec, name: str, normal: bool = True) -> None:
    rows = []
    for d in ("down", "right", "up"):
        rows.append([frame(spec, d, f).render() for f in (0, 1, 2)])
    img = sheet(rows)
    save(img, out("characters", f"{name}_walk.png"))
    if normal:
        save(sheet_normal(img, 32, 48), out("characters", f"{name}_walk_n.png"))


def strip(frames, path: str, normal: bool = False, fw: int = 0, fh: int = 0) -> None:
    img = sheet([frames])
    save(img, path)
    if normal:
        save(sheet_normal(img, fw or frames[0].shape[1], fh or frames[0].shape[0]), path.replace(".png", "_n.png"))


def gen_characters() -> None:
    walk_sheet(MC, "mc")
    walk_sheet(COUNCIL, "council")
    walk_sheet(ARBITER, "arbiter")
    walk_sheet(SAINT, "saint")
    walk_sheet(GUARD, "guard")
    walk_sheet(MAREN, "maren")
    walk_sheet(HUNTER, "hunter")
    strip([pose_kneel(MC).render(), pose_kneel(MC, look_up=True).render(), pose_burden(MC, 0).render(),
           pose_burden(MC, 1).render(), pose_kneel(MC, "closed").render(), pose_kneel_back(MC).render()],
          out("characters", "mc_poses.png"), True, 32, 48)
    strip([pose_battle(MC, k, f).render() for k, f in (("idle", 0), ("idle", 1), ("attack", 0), ("hurt", 0),
                                                         ("cast", 0), ("guard", 0), ("down", 0))],
          out("characters", "mc_battle.png"), True, 32, 48)
    strip([frame(SAINT, "down", 0, arms="raise").render(), frame(SAINT, "right", 0, arms="raise").render()],
          out("characters", "saint_poses.png"), True, 32, 48)
    strip([frame(MAREN, "down", 0, arms="lantern").render(), frame(MAREN, "right", 0, arms="lantern").render(),
           frame(MAREN, "right", 1, arms="lantern").render(), frame(MAREN, "right", 2, arms="lantern").render()],
          out("characters", "maren_poses.png"), True, 32, 48)
    strip([frame(ARBITER, "down", 0, arms="raise").render(), frame(COUNCIL, "down", 0, arms="pray").render()],
          out("characters", "synod_poses.png"), True, 32, 48)
    strip([cr.exiled("idle", 0).render(), cr.exiled("idle", 1).render(), cr.exiled("roar", 0).render(),
           cr.exiled("lunge", 0).render()], out("characters", "exiled.png"), True, 96, 96)
    strip([cr.hound("idle", 0).render(), cr.hound("idle", 1).render(), cr.hound("attack", 0).render(),
           cr.hound("hurt", 0).render(), cr.hound("crouch", 0).render()], out("characters", "hound.png"), True, 48, 32)
    strip([cr.boar("idle", 0).render(), cr.boar("idle", 1).render(), cr.boar("attack", 0).render(),
           cr.boar("hurt", 0).render()], out("characters", "boar.png"), True, 48, 32)
    strip([cr.goat("idle", 0).render(), cr.goat("idle", 1).render(), cr.goat("walk", 0).render(),
           cr.goat("walk", 1).render(), cr.goat("eat", 0).render()], out("characters", "goat.png"), True, 28, 24)
    strip([cr.crow(0).render(), cr.crow(1).render()], out("characters", "crow.png"))
    save(cr.light_lance().render(outline=False), out("props", "light_lance.png"))


def gen_portraits() -> None:
    for pid, (spec, exprs) in PORTRAITS.items():
        for e in exprs:
            save(pt.bust(spec, e).render(), out("portraits", f"{pid}_{e}.png"))


def gen_backgrounds() -> None:
    tr = env.tribunal()
    save(tr["color"], out("backgrounds", "tribunal.png"))
    save(tr["normal"], out("backgrounds", "tribunal_n.png"))
    save(tr["emissive"], out("backgrounds", "tribunal_e.png"))
    p, pn = env.pillar(170)
    save(p, out("props", "pillar.png"))
    save(pn, out("props", "pillar_n.png"))
    save(env.candelabra(), out("props", "candelabra.png"))
    strip(env.flame_frames(), out("props", "flame.png"))

    st = env.colossal_stone()
    save(st["color"], out("backgrounds", "stone_colossal.png"))
    save(st["normal"], out("backgrounds", "stone_colossal_n.png"))
    save(st["emissive"], out("backgrounds", "stone_colossal_e.png"))
    far = env.mountains_layer(800, 200, 501, 60, 0.6, env.pal("#0c0c1a", "#121428", "#1a1e34", "#242a42"), True)
    mid = env.mountains_layer(800, 170, 502, 30, 0.55, env.pal("#08080e", "#0e0e18", "#141622", "#1c1e2c"), False)
    save(far, out("backgrounds", "peak_far.png"))
    save(mid, out("backgrounds", "peak_mid.png"))
    cg = env.cliff_ground(640, 110, 503)
    save(cg["color"], out("backgrounds", "peak_ground.png"))
    save(cg["normal"], out("backgrounds", "peak_ground_n.png"))
    save(env.iron_stake(), out("props", "iron_stake.png"))
    save(env.chain_link(), out("props", "chain_link.png"))

    bf = env.battle_forest()
    save(bf["color"], out("backgrounds", "battle_forest.png"))

    wg = env.wilds_ground(960, 720)
    save(wg["color"], out("backgrounds", "wilds_ground.png"))
    save(wg["normal"], out("backgrounds", "wilds_ground_n.png"))
    # export the path / stream curves so the Godot scene can place props and collisions sensibly
    layout = os.path.join(ROOT, "scripts", "world", "wilds_layout.gd")
    with open(layout, "w") as fh:
        fh.write("## Generated by tools/gen_art.py -- do not edit by hand.\n")
        fh.write("## Curves of the dirt path and the stream painted into wilds_ground.png.\n")
        fh.write("class_name WildsLayout\n\n")
        fh.write("const STEP := 16\n")
        fh.write("const SIZE := Vector2i(960, 720)\n")
        fh.write("const PATH_Y: Array[int] = [%s]\n" % ", ".join(str(int(wg["path_y"][x])) for x in range(0, 960, 16)))
        fh.write("const STREAM_X: Array[int] = [%s]\n" % ", ".join(str(int(wg["stream_x"][y])) for y in range(0, 720, 16)))
        fh.write("\n\nstatic func path_y_at(x: float) -> float:\n")
        fh.write("\tvar i := clampi(int(x / STEP), 0, PATH_Y.size() - 2)\n")
        fh.write("\tvar t := clampf((x - i * STEP) / float(STEP), 0.0, 1.0)\n")
        fh.write("\treturn lerpf(PATH_Y[i], PATH_Y[i + 1], t)\n")
        fh.write("\n\nstatic func stream_x_at(y: float) -> float:\n")
        fh.write("\tvar i := clampi(int(y / STEP), 0, STREAM_X.size() - 2)\n")
        fh.write("\tvar t := clampf((y - i * STEP) / float(STEP), 0.0, 1.0)\n")
        fh.write("\treturn lerpf(STREAM_X[i], STREAM_X[i + 1], t)\n")

    sc = env.synod_chamber()
    save(sc["color"], out("backgrounds", "synod_chamber.png"))
    save(sc["normal"], out("backgrounds", "synod_chamber_n.png"))
    save(sc["emissive"], out("backgrounds", "synod_chamber_e.png"))
    save(env.desk(), out("props", "desk.png"))


def gen_props() -> None:
    for i, (w, h, seed, palette) in enumerate(((56, 72, 601, env.LEAF_PAL), (64, 80, 602, env.LEAF_PAL),
                                               (60, 76, 603, env.AUTUMN_PAL))):
        img, nm = env.tree_canopy(w, h, seed, palette, 18)
        save(img, out("props", f"tree_{i}.png"))
        save(nm, out("props", f"tree_{i}_n.png"))
    big, bign = env.tree_canopy(110, 130, 610, env.LEAF_PAL, 34)
    save(big, out("props", "tree_big.png"))
    save(bign, out("props", "tree_big_n.png"))
    for i, (w, h, seed) in enumerate(((30, 64, 620), (36, 80, 621))):
        img, nm = env.pine(w, h, seed)
        save(img, out("props", f"pine_{i}.png"))
        save(nm, out("props", f"pine_{i}_n.png"))
    for i in range(2):
        save(env.bush(630 + i), out("props", f"bush_{i}.png"))
    for i, (w, h) in enumerate(((22, 16), (40, 28))):
        img, nm = env.rock(w, h, 640 + i)
        save(img, out("props", f"rock_{i}.png"))
        save(nm, out("props", f"rock_{i}_n.png"))
    save(env.log_prop(), out("props", "log.png"))
    save(env.branch_pickup(), out("props", "pickup_branch.png"))
    save(env.stone_pickup(), out("props", "pickup_stone.png"))
    save(env.herb_pickup(), out("props", "pickup_herb.png"))
    strip(env.campfire_frames(), out("props", "campfire.png"))
    save(env.lean_to(), out("props", "lean_to.png"))
    save(env.bedroll(), out("props", "bedroll.png"))
    save(env.wanted_post(), out("props", "wanted_post.png"))
    for i, roof in enumerate(("thatch", "tile", "thatch")):
        img, emi = env.house(650 + i, roof)
        save(img, out("props", f"house_{i}.png"))
        save(emi, out("props", f"house_{i}_e.png"))
    save(env.fence(), out("props", "fence.png"))
    lp, lpe = env.lamp_post()
    save(lp, out("props", "lamp_post.png"))
    save(lpe, out("props", "lamp_post_e.png"))
    save(env.well(), out("props", "well.png"))


# ---------------------------------------------------------------------------
# UI icons
# ---------------------------------------------------------------------------
def icon(kind: str) -> np.ndarray:
    s = MatSprite(16, 16)
    if kind == "blunt":  # chain / fist
        m = s.m("iron", ramp("#3a3a46", "#8a8c9c", "#d0d2e0"))
        for i in range(3):
            s.ellipse(4 + i * 4, 11 - i * 3, 2.5, 2, m)
        s.ellipse(12, 3, 2.5, 2, m)
    elif kind == "pierce":
        m = s.m("stone", ramp("#5a5040", "#a89878", "#e8dcc0"))
        s.poly([(2, 13), (11, 4), (14, 2), (12, 5), (3, 14)], m)
        s.poly([(10, 2), (14, 2), (14, 6)], m)
    elif kind == "fire":
        m = s.m("fire", ramp("#a02010", "#ff7020", "#ffe080"))
        c = s.m("core", ramp("#ffc040", "#fff0a0", "#ffffff"), flat=True)
        s.poly([(8, 1), (13, 8), (12, 13), (8, 15), (4, 13), (3, 8), (6, 5), (7, 8)], m)
        s.ellipse(8, 11, 2.5, 3, c)
    elif kind == "holy":
        m = s.m("holy", ramp("#a07010", "#f0c040", "#fff8c0"))
        s.ellipse(8, 8, 3.5, 3.5, m)
        for (a, b, c2, d) in ((8, 1, 8, 3), (8, 13, 8, 15), (1, 8, 3, 8), (13, 8, 15, 8), (3, 3, 4, 4),
                              (12, 12, 13, 13), (3, 13, 4, 12), (12, 4, 13, 3)):
            s.line(a, b, c2, d, m)
    elif kind == "dark":
        m = s.m("dark", ramp("#200a30", "#5a2a8a", "#a070e0"))
        s.ellipse(8, 8, 6, 6, m)
        s.ellipse(10, 6, 4.5, 4.5, s.m("hole", ramp("#000000", "#000000", "#000000")))
    elif kind == "unknown":
        m = s.m("q", ramp("#3a3a46", "#8a8c9c", "#d0d2e0"))
        s.rect(5, 2, 10, 3, m)
        s.rect(10, 3, 11, 7, m)
        s.rect(7, 7, 10, 8, m)
        s.rect(7, 9, 8, 10, m)
        s.rect(7, 12, 8, 13, m)
    elif kind == "shield":
        m = s.m("shield", ramp("#2a3a5a", "#5a7ab0", "#a0c0f0"))
        r = s.m("rim", ramp("#5a4010", "#c09030", "#f8e080"))
        s.poly([(2, 2), (14, 2), (14, 8), (8, 15), (2, 8)], r)
        s.poly([(4, 4), (12, 4), (12, 8), (8, 12), (4, 8)], m)
    elif kind == "broken":
        m = s.m("shield", ramp("#3a2a2a", "#7a5050", "#b08080"))
        s.poly([(2, 2), (7, 2), (6, 7), (8, 9), (6, 14), (2, 8)], m)
        s.poly([(9, 2), (14, 2), (14, 8), (10, 14), (11, 9), (9, 7)], m)
    elif kind == "boost":
        m = s.m("boost", ramp("#a04010", "#ff8a30", "#ffe0a0"))
        s.ellipse(8, 8, 5, 5, m)
        s.ellipse(8, 8, 2, 2, s.m("core", ramp("#fff0c0", "#ffffff", "#ffffff"), flat=True))
    elif kind == "boost_empty":
        m = s.m("boost", ramp("#202028", "#3a3a48", "#5a5a6a"))
        s.ellipse(8, 8, 5, 5, m)
    elif kind == "herb":
        return env.herb_pickup()
    return s.render()


def gen_ui() -> None:
    for k in ("blunt", "pierce", "fire", "holy", "dark", "unknown", "shield", "broken", "boost", "boost_empty",
              "herb"):
        img = icon(k)
        if k == "dark":
            img[(img[..., 0] == 0) & (img[..., 1] == 0) & (img[..., 2] == 0)] = (0, 0, 0, 0)
        save(img, out("ui", f"icon_{k}.png"))
    # 1x1-ish noise texture used by shaders (film grain / dust)
    rng = np.random.default_rng(5)
    noise = np.zeros((64, 64, 4), np.uint8)
    v = (rng.random((64, 64)) * 255).astype(np.uint8)
    noise[..., 0] = v
    noise[..., 1] = np.roll(v, 7, 0)
    noise[..., 2] = np.roll(v, 13, 1)
    noise[..., 3] = 255
    save(noise, out("ui", "noise.png"))


def main() -> None:
    gen_characters()
    gen_portraits()
    gen_backgrounds()
    gen_props()
    gen_ui()
    print("Art generated in", OUT)


if __name__ == "__main__":
    main()
