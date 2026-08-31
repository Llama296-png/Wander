#!/usr/bin/env python3
"""Generates every pixel-art asset for Wander: animation frames for player/
ally/enemy actors, item/projectile/tile/door art, and room-theme floor/wall/
prop textures.

Run with `python3 gen_art.py` from anywhere; writes PNGs into
../assets/sprites relative to this file. Kept in the repo so the art can be
regenerated or tweaked later without hand-editing pixels.

Convention: every actor frame is authored FACING RIGHT at rest (weapon/head
leading on the +X side). In-game the whole sprite is rotated to face the
mouse cursor, so `rotation = 0` must already read as "facing right".
"""
import math
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
os.makedirs(OUT, exist_ok=True)

S = 16  # canvas size for items/projectiles/tiles/doors
A = 24  # canvas size for animated actors (player/ally/enemy) -- a bit
        # bigger so there's room for a visible weapon, hands and shading
OUTLINE = (24, 18, 26, 255)
SHADOW = (20, 16, 24, 130)


def canvas():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


def actor_canvas():
    return Image.new("RGBA", (A, A), (0, 0, 0, 0))


def save(img, name):
    img.save(os.path.join(OUT, name))


def fade(img, alpha_mult):
    r, g, b, a = img.split()
    a = a.point(lambda p: int(p * alpha_mult))
    return Image.merge("RGBA", (r, g, b, a))


# ---------------------------------------------------------------------------
# Humanoid actors (player warrior/mage/priest, ally warrior/mage/priest,
# enemy skeleton) -- one parametric template, posed per animation frame.
# ---------------------------------------------------------------------------

def humanoid(body, skin, accent, weapon, *, leg=0, arm_deg=20, bob=0,
             cast_glow=0.0, bone=False):
    """leg: -3..3 stride offset. arm_deg: weapon angle, 0=pointing right,
    positive rotates it upward. bob: vertical body offset (breathing/step).
    cast_glow: 0..1, draws a growing orb at the weapon tip for casters."""
    img = actor_canvas()
    d = ImageDraw.Draw(img)
    leg_color = skin if bone else tuple(max(0, c - 25) for c in body[:3]) + (255,)
    shoe_color = (40, 34, 30, 255)

    d.ellipse([6, 20, 17, 23], fill=SHADOW)
    # trailing (back) leg then leading (front) leg, offset by stride, with a
    # gap between them so they read as two legs rather than one blob
    d.rectangle([6, 16 + bob, 9, 21 + bob - leg], fill=leg_color, outline=OUTLINE)
    d.rectangle([6, 20 + bob - leg, 9, 21 + bob - leg], fill=shoe_color)
    d.rectangle([13, 16 + bob, 16, 21 + bob + leg], fill=leg_color, outline=OUTLINE)
    d.rectangle([13, 20 + bob + leg, 16, 21 + bob + leg], fill=shoe_color)

    # torso, two-tone (lit top / shaded bottom) for a bit of depth
    d.rounded_rectangle([4, 6 + bob, 17, 18 + bob], radius=3, fill=body, outline=OUTLINE)
    lit = tuple(min(255, c + 28) for c in body[:3]) + (255,)
    d.rounded_rectangle([4, 6 + bob, 17, 11 + bob], radius=3, fill=lit)
    d.line([(4, 12 + bob), (17, 12 + bob)], fill=accent, width=2)

    # head (leading, right side)
    d.ellipse([10, 1 + bob, 20, 11 + bob], fill=skin, outline=OUTLINE)
    d.ellipse([16, 4 + bob, 18, 6 + bob], fill=OUTLINE)
    if bone:
        d.ellipse([12, 4 + bob, 14, 6 + bob], fill=OUTLINE)
        d.line([(12, 8 + bob), (18, 8 + bob)], fill=OUTLINE, width=1)
    else:
        d.arc([12, 5 + bob, 18, 10 + bob], 20, 160, fill=OUTLINE)

    # shoulder/hand + weapon, swung by arm_deg around the shoulder
    shoulder = (13, 13 + bob)
    rad = math.radians(-arm_deg)
    length = {"sword": 6, "staff": 7, "symbol": 5}.get(weapon, 5)
    tip = (shoulder[0] + length * math.cos(rad), shoulder[1] + length * math.sin(rad))
    d.ellipse([shoulder[0] - 2, shoulder[1] - 2, shoulder[0] + 2, shoulder[1] + 2], fill=skin, outline=OUTLINE)
    d.line([shoulder, tip], fill=(72, 54, 46, 255), width=3)
    if weapon == "sword":
        blade = (shoulder[0] + (length + 4) * math.cos(rad), shoulder[1] + (length + 4) * math.sin(rad))
        d.line([tip, blade], fill=(215, 215, 225, 255), width=2)
        d.line([tip, blade], fill=(240, 240, 248, 255), width=1)
        d.ellipse([tip[0] - 1.5, tip[1] - 1.5, tip[0] + 1.5, tip[1] + 1.5], fill=accent, outline=OUTLINE)
    elif weapon == "staff":
        d.ellipse([tip[0] - 2.5, tip[1] - 2.5, tip[0] + 2.5, tip[1] + 2.5], fill=accent, outline=OUTLINE)
        d.ellipse([tip[0] - 1, tip[1] - 1, tip[0] + 1, tip[1] + 1], fill=(255, 255, 255, 180))
    elif weapon == "symbol":
        d.line([(tip[0] - 3, tip[1]), (tip[0] + 3, tip[1])], fill=accent, width=2)
        d.line([(tip[0], tip[1] - 3), (tip[0], tip[1] + 3)], fill=accent, width=2)

    if cast_glow > 0.01:
        r = 1.0 + 3.0 * cast_glow
        d.ellipse([tip[0] - r, tip[1] - r, tip[0] + r, tip[1] + r],
                   fill=(accent[0], accent[1], accent[2], int(200 * cast_glow)))

    return img


def humanoid_set(prefix, body, skin, accent, weapon, ranged, bone=False):
    idle = [
        humanoid(body, skin, accent, weapon, bob=0, arm_deg=15, bone=bone),
        humanoid(body, skin, accent, weapon, bob=-1, arm_deg=18, bone=bone),
    ]
    walk = [
        humanoid(body, skin, accent, weapon, leg=3, bob=0, arm_deg=10, bone=bone),
        humanoid(body, skin, accent, weapon, leg=0, bob=-1, arm_deg=15, bone=bone),
        humanoid(body, skin, accent, weapon, leg=-3, bob=0, arm_deg=10, bone=bone),
        humanoid(body, skin, accent, weapon, leg=0, bob=-1, arm_deg=15, bone=bone),
    ]
    if ranged:
        attack = [
            humanoid(body, skin, accent, weapon, arm_deg=35, cast_glow=0.2, bone=bone),
            humanoid(body, skin, accent, weapon, arm_deg=25, cast_glow=0.6, bone=bone),
            humanoid(body, skin, accent, weapon, arm_deg=15, cast_glow=1.0, bone=bone),
        ]
    else:
        attack = [
            humanoid(body, skin, accent, weapon, arm_deg=60, bone=bone),
            humanoid(body, skin, accent, weapon, arm_deg=-30, bone=bone),
            humanoid(body, skin, accent, weapon, arm_deg=15, bone=bone),
        ]
    base_death = humanoid(body, skin, accent, weapon, arm_deg=15, bone=bone)
    death = death_frames(base_death)

    for i, f in enumerate(idle):
        save(f, f"{prefix}_idle_{i}.png")
    for i, f in enumerate(walk):
        save(f, f"{prefix}_walk_{i}.png")
    for i, f in enumerate(attack):
        save(f, f"{prefix}_attack_{i}.png")
    for i, f in enumerate(death):
        save(f, f"{prefix}_death_{i}.png")


def death_frames(base, count=4):
    frames = []
    cx, cy = base.width / 2.0, base.height * 0.75
    for i in range(count):
        t = i / (count - 1)
        angle = -t * 85
        alpha = 1.0 - 0.55 * t
        rotated = base.rotate(angle, resample=Image.BICUBIC, center=(cx, cy), expand=False)
        frames.append(fade(rotated, alpha))
    return frames


# ---------------------------------------------------------------------------
# Enemies with bespoke shapes: slime, bat, brute (skeleton reuses humanoid)
# ---------------------------------------------------------------------------

def slime(color, *, squash=0.0, lunge=0):
    img = actor_canvas()
    d = ImageDraw.Draw(img)
    h = 14 - squash * 5
    top = 22 - h
    dark = tuple(max(0, c - 40) for c in color[:3]) + (255,)
    d.ellipse([5, 20, 19, 23], fill=SHADOW)
    d.ellipse([3 + lunge, top, 21 + lunge, 22], fill=color, outline=OUTLINE)
    d.chord([3 + lunge, top + h * 0.5, 21 + lunge, 22], 0, 180, fill=dark)
    d.ellipse([6 + lunge, top + 3, 11 + lunge, top + 6], fill=(255, 255, 255, 120))
    d.ellipse([8 + lunge, 16, 10 + lunge, 18], fill=OUTLINE)
    d.ellipse([14 + lunge, 16, 16 + lunge, 18], fill=OUTLINE)
    if lunge:
        d.polygon([(20 + lunge, 18), (25 + lunge, 16), (20 + lunge, 14)], fill=(230, 60, 60, 255))
    return img


def slime_set():
    color = (70, 200, 110, 255)
    idle = [slime(color, squash=0.0), slime(color, squash=0.5)]
    walk = [slime(color, squash=0.8), slime(color, squash=0.0), slime(color, squash=0.8), slime(color, squash=0.2)]
    attack = [slime(color, squash=0.6, lunge=0), slime(color, squash=0.1, lunge=3)]
    death = death_frames(slime(color, squash=0.0), count=3)
    for i, f in enumerate(idle):
        save(f, f"enemy_slime_idle_{i}.png")
    for i, f in enumerate(walk):
        save(f, f"enemy_slime_walk_{i}.png")
    for i, f in enumerate(attack):
        save(f, f"enemy_slime_attack_{i}.png")
    for i, f in enumerate(death):
        save(f, f"enemy_slime_death_{i}.png")


def bat(color, *, wing=0.0, lunge=0):
    img = actor_canvas()
    d = ImageDraw.Draw(img)
    w = 6 + wing * 5
    d.polygon([(1, 10 - w * 0.35), (8, 12), (1, 14 + w * 0.35), (4, 12)], fill=color, outline=OUTLINE)
    d.polygon([(23, 10 - w * 0.35), (16, 12), (23, 14 + w * 0.35), (20, 12)], fill=color, outline=OUTLINE)
    d.ellipse([8 + lunge, 7, 16 + lunge, 18], fill=color, outline=OUTLINE)
    d.polygon([(9 + lunge, 8), (10 + lunge, 5), (11 + lunge, 8)], fill=color, outline=OUTLINE)
    d.polygon([(13 + lunge, 8), (14 + lunge, 5), (15 + lunge, 8)], fill=color, outline=OUTLINE)
    d.ellipse([10 + lunge, 12, 13 + lunge, 15], fill=(230, 40, 60, 255))
    d.ellipse([14 + lunge, 12, 17 + lunge, 15], fill=(230, 40, 60, 255))
    if lunge:
        d.polygon([(16 + lunge, 16), (19 + lunge, 15), (16 + lunge, 14)], fill=(240, 240, 245, 255))
    return img


def bat_set():
    color = (60, 50, 70, 255)
    idle = [bat(color, wing=0.2), bat(color, wing=0.8)]
    walk = [bat(color, wing=0.0), bat(color, wing=1.0), bat(color, wing=0.3), bat(color, wing=0.8)]
    attack = [bat(color, wing=1.0, lunge=0), bat(color, wing=0.2, lunge=3)]
    death = death_frames(bat(color, wing=0.3), count=3)
    for i, f in enumerate(idle):
        save(f, f"enemy_bat_idle_{i}.png")
    for i, f in enumerate(walk):
        save(f, f"enemy_bat_walk_{i}.png")
    for i, f in enumerate(attack):
        save(f, f"enemy_bat_attack_{i}.png")
    for i, f in enumerate(death):
        save(f, f"enemy_bat_death_{i}.png")


def brute(color, *, leg=0, arm_deg=15, bob=0):
    img = actor_canvas()
    d = ImageDraw.Draw(img)
    dark = tuple(max(0, c - 35) for c in color[:3]) + (255,)
    d.ellipse([2, 20, 22, 23], fill=SHADOW)
    d.rectangle([5, 15 + bob, 9, 21 + bob - leg], fill=(110, 50, 38, 255), outline=OUTLINE)
    d.rectangle([12, 15 + bob, 16, 21 + bob + leg], fill=(110, 50, 38, 255), outline=OUTLINE)
    d.polygon([(3, 6 + bob), (20, 6 + bob), (23, 20 + bob), (0, 20 + bob)], fill=color, outline=OUTLINE)
    d.polygon([(3, 6 + bob), (20, 6 + bob), (18, 11 + bob), (5, 11 + bob)], fill=dark)
    d.ellipse([12, -1 + bob, 23, 10 + bob], fill=(200, 160, 120, 255), outline=OUTLINE)
    d.ellipse([19, 3 + bob, 21, 5 + bob], fill=OUTLINE)
    d.line([(18, 8 + bob), (14, 9 + bob)], fill=(120, 30, 24, 255), width=2)
    shoulder = (19, 9 + bob)
    rad = math.radians(-arm_deg)
    tip = (shoulder[0] + 9 * math.cos(rad), shoulder[1] + 9 * math.sin(rad))
    d.line([shoulder, tip], fill=(110, 50, 38, 255), width=4)
    d.ellipse([tip[0] - 2, tip[1] - 2, tip[0] + 2, tip[1] + 2], fill=(90, 40, 30, 255), outline=OUTLINE)
    return img


def brute_set():
    color = (170, 60, 50, 255)
    idle = [brute(color, bob=0, arm_deg=15), brute(color, bob=-1, arm_deg=18)]
    walk = [brute(color, leg=3, bob=0), brute(color, leg=0, bob=-1), brute(color, leg=-3, bob=0), brute(color, leg=0, bob=-1)]
    attack = [brute(color, arm_deg=70), brute(color, arm_deg=-40), brute(color, arm_deg=15)]
    death = death_frames(brute(color, arm_deg=15), count=4)
    for i, f in enumerate(idle):
        save(f, f"enemy_brute_idle_{i}.png")
    for i, f in enumerate(walk):
        save(f, f"enemy_brute_walk_{i}.png")
    for i, f in enumerate(attack):
        save(f, f"enemy_brute_attack_{i}.png")
    for i, f in enumerate(death):
        save(f, f"enemy_brute_death_{i}.png")


# ---------------------------------------------------------------------------
# Items, projectiles, tiles, doors, icon -- refreshed with a bit more shading
# ---------------------------------------------------------------------------

def potion(liquid):
    img = canvas()
    d = ImageDraw.Draw(img)
    d.rectangle([6, 2, 9, 4], fill=(150, 150, 160, 255), outline=OUTLINE)
    d.ellipse([4, 5, 11, 14], fill=(230, 240, 250, 200), outline=OUTLINE)
    d.ellipse([5, 7, 10, 13], fill=liquid)
    d.ellipse([5, 7, 10, 9], fill=tuple(min(255, c + 40) for c in liquid[:3]) + (liquid[3],))
    d.point((6, 8), fill=(255, 255, 255, 200))
    return img


def gold_coin():
    img = canvas()
    d = ImageDraw.Draw(img)
    d.ellipse([3, 3, 12, 12], fill=(255, 205, 60, 255), outline=(150, 100, 10, 255))
    d.ellipse([5, 5, 10, 10], fill=(255, 230, 120, 255))
    d.arc([4, 4, 11, 11], 200, 260, fill=(255, 255, 255, 200))
    return img


def gem(color):
    img = canvas()
    d = ImageDraw.Draw(img)
    d.polygon([(8, 2), (13, 7), (8, 14), (3, 7)], fill=color, outline=OUTLINE)
    d.polygon([(8, 2), (10, 7), (8, 14), (6, 7)], fill=(255, 255, 255, 90))
    d.polygon([(8, 2), (10, 7), (8, 7)], fill=(255, 255, 255, 130))
    return img


def projectile(color):
    img = canvas()
    d = ImageDraw.Draw(img)
    d.ellipse([4, 4, 12, 12], fill=(color[0], color[1], color[2], 90))
    d.ellipse([5, 5, 11, 11], fill=color, outline=OUTLINE)
    d.ellipse([6, 6, 9, 9], fill=(255, 255, 255, 170))
    return img


def arrow():
    img = canvas()
    d = ImageDraw.Draw(img)
    d.line([(2, 8), (13, 8)], fill=(150, 110, 70, 255), width=2)
    d.polygon([(13, 5), (15, 8), (13, 11)], fill=(200, 200, 210, 255), outline=OUTLINE)
    d.line([(2, 6), (4, 8)], fill=(220, 60, 60, 255), width=1)
    d.line([(2, 10), (4, 8)], fill=(220, 60, 60, 255), width=1)
    return img


def tile(base, hi, lo, dots):
    img = canvas()
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, S - 1, S - 1], fill=base)
    d.line([(0, 0), (S - 1, 0)], fill=hi)
    d.line([(0, 0), (0, S - 1)], fill=hi)
    d.line([(0, S - 1), (S - 1, S - 1)], fill=lo)
    d.line([(S - 1, 0), (S - 1, S - 1)], fill=lo)
    for (x, y) in dots:
        d.point((x, y), fill=hi)
    return img


def door(open_):
    img = canvas()
    d = ImageDraw.Draw(img)
    if open_:
        d.rectangle([0, 0, 15, 15], fill=(24, 18, 26, 255))
        d.rectangle([1, 1, 14, 14], fill=(10, 8, 12, 255))
    else:
        d.rectangle([0, 0, 15, 15], fill=(120, 78, 44, 255), outline=OUTLINE)
        d.line([(4, 0), (4, 15)], fill=(90, 58, 32, 255))
        d.line([(11, 0), (11, 15)], fill=(90, 58, 32, 255))
        d.ellipse([11, 7, 13, 9], fill=(230, 200, 90, 255))
    return img


def icon():
    img = canvas()
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, S - 1, S - 1], fill=(58, 50, 62, 255))
    mini = humanoid((90, 140, 210, 255), (235, 200, 165, 255), (230, 200, 90, 255), "sword").resize((S, S), Image.LANCZOS)
    img.alpha_composite(mini)
    return img


# ---------------------------------------------------------------------------
# Room-theme floor / wall / prop art
# ---------------------------------------------------------------------------

def prop_rect(w, h, fill, outline=OUTLINE, detail=None):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([0, h - 3, w - 1, h - 1], fill=SHADOW)
    d.rounded_rectangle([1, 1, w - 2, h - 4], radius=2, fill=fill, outline=outline)
    if detail:
        detail(d, w, h)
    return img


THEMES = {
    "bathroom": dict(
        floor=lambda: tile((225, 235, 238, 255), (240, 248, 250, 255), (200, 212, 216, 255), [(4, 4), (12, 4), (4, 12), (12, 12)]),
        wall=lambda: tile((190, 215, 220, 255), (210, 232, 236, 255), (150, 178, 184, 255), [(2, 2), (8, 2), (14, 2)]),
        props={
            "bathtub": prop_rect(28, 16, (250, 250, 252, 255), detail=lambda d, w, h: d.ellipse([3, 3, w - 4, h - 6], outline=(190, 200, 205, 255))),
            "sink": prop_rect(14, 12, (245, 245, 248, 255), detail=lambda d, w, h: d.ellipse([3, 2, w - 4, h - 5], fill=(210, 225, 230, 255))),
        },
    ),
    "living_room": dict(
        floor=lambda: tile((150, 108, 66, 255), (168, 124, 78, 255), (128, 90, 52, 255), [(2, 6), (10, 2), (6, 12)]),
        wall=lambda: tile((196, 168, 132, 255), (212, 186, 150, 255), (168, 140, 104, 255), [(4, 4), (12, 8)]),
        props={
            "couch": prop_rect(30, 16, (140, 40, 46, 255), detail=lambda d, w, h: d.rectangle([2, 2, w - 3, 6], fill=(160, 55, 60, 255))),
            "tv": prop_rect(18, 14, (30, 28, 32, 255), detail=lambda d, w, h: d.rectangle([2, 2, w - 3, h - 6], fill=(90, 170, 220, 200))),
        },
    ),
    "garage": dict(
        floor=lambda: tile((110, 110, 116, 255), (128, 128, 134, 255), (86, 86, 92, 255), [(3, 3), (9, 9), (13, 5)]),
        wall=lambda: tile((96, 96, 102, 255), (116, 116, 122, 255), (70, 70, 76, 255), [(2, 2), (2, 8), (2, 14)]),
        props={
            "car": prop_rect(30, 18, (170, 40, 40, 255), detail=lambda d, w, h: d.rounded_rectangle([4, 2, w - 5, 8], radius=3, fill=(210, 220, 230, 220))),
            "toolbox": prop_rect(14, 12, (90, 92, 98, 255), detail=lambda d, w, h: d.rectangle([2, 4, w - 3, 5], fill=(220, 60, 40, 255))),
        },
    ),
    "bedroom": dict(
        floor=lambda: tile((186, 156, 122, 255), (202, 174, 140, 255), (162, 134, 100, 255), [(4, 4), (10, 10)]),
        wall=lambda: tile((168, 188, 210, 255), (188, 206, 226, 255), (140, 160, 184, 255), [(6, 4), (10, 10)]),
        props={
            "bed": prop_rect(26, 18, (230, 235, 240, 255), detail=lambda d, w, h: (d.rectangle([2, 2, 10, 8], fill=(240, 245, 248, 255)), d.rectangle([2, 9, w - 3, h - 6], fill=(90, 130, 180, 255)))),
            "dresser": prop_rect(16, 12, (120, 84, 54, 255), detail=lambda d, w, h: (d.line([(2, 5), (w - 3, 5)], fill=(90, 60, 36, 255)), d.line([(2, 9), (w - 3, 9)], fill=(90, 60, 36, 255)))),
        },
    ),
    "master_bedroom": dict(
        floor=lambda: tile((110, 40, 60, 255), (130, 52, 74, 255), (90, 30, 48, 255), [(4, 4), (12, 4), (4, 12), (12, 12), (8, 8)]),
        wall=lambda: tile((70, 54, 40, 255), (110, 88, 60, 255), (52, 40, 28, 255), [(2, 2), (14, 14), (2, 14), (14, 2)]),
        props={
            "big_bed": prop_rect(32, 20, (245, 240, 250, 255), detail=lambda d, w, h: (d.rectangle([2, 2, 12, 9], fill=(250, 245, 252, 255)), d.rectangle([16, 2, 26, 9], fill=(250, 245, 252, 255)), d.rectangle([2, 10, w - 3, h - 6], fill=(150, 40, 60, 255)))),
            "vanity": prop_rect(16, 14, (200, 180, 140, 255), detail=lambda d, w, h: d.ellipse([3, 2, w - 4, 8], fill=(210, 230, 240, 200), outline=(230, 210, 150, 255))),
        },
    ),
    "kitchen": dict(
        floor=lambda: tile((235, 235, 230, 255), (250, 250, 248, 255), (60, 60, 60, 255), [(0, 0), (8, 8)]),
        wall=lambda: tile((210, 228, 210, 255), (228, 240, 228, 255), (170, 195, 170, 255), [(4, 4), (12, 4), (4, 12)]),
        props={
            "stove": prop_rect(16, 14, (40, 40, 44, 255), detail=lambda d, w, h: (d.ellipse([2, 2, 7, 7], fill=(210, 60, 40, 255)), d.ellipse([9, 2, 14, 7], fill=(80, 80, 84, 255)))),
            "fridge": prop_rect(16, 20, (225, 228, 232, 255), detail=lambda d, w, h: d.line([(2, 9), (w - 3, 9)], fill=(180, 184, 190, 255))),
        },
    ),
}


def gen_themes():
    for name, spec in THEMES.items():
        save(spec["floor"](), f"theme_{name}_floor.png")
        save(spec["wall"](), f"theme_{name}_wall.png")
        for prop_name, img in spec["props"].items():
            save(img, f"theme_{name}_prop_{prop_name}.png")


# ---------------------------------------------------------------------------

def main():
    humanoid_set("player_warrior", (90, 110, 200, 255), (235, 200, 165, 255), (210, 210, 220, 255), "sword", ranged=False)
    humanoid_set("player_mage", (150, 70, 200, 255), (235, 200, 165, 255), (90, 220, 230, 255), "staff", ranged=True)
    humanoid_set("player_priest", (235, 225, 200, 255), (235, 200, 165, 255), (255, 210, 90, 255), "symbol", ranged=True)

    humanoid_set("ally_warrior", (70, 90, 160, 255), (225, 190, 155, 255), (180, 180, 190, 255), "sword", ranged=False)
    humanoid_set("ally_mage", (120, 55, 160, 255), (225, 190, 155, 255), (70, 190, 200, 255), "staff", ranged=True)
    humanoid_set("ally_priest", (205, 195, 175, 255), (225, 190, 155, 255), (225, 180, 70, 255), "symbol", ranged=True)

    humanoid_set("enemy_skeleton", (232, 226, 210, 255), (232, 226, 210, 255), (200, 190, 170, 255), "sword", ranged=False, bone=True)
    slime_set()
    bat_set()
    brute_set()

    save(potion((220, 60, 90, 255)), "item_potion.png")
    save(potion((230, 60, 220, 255)), "item_mega_potion.png")
    save(gold_coin(), "item_gold.png")
    save(gem((230, 90, 90, 255)), "item_power_gem.png")
    save(gem((90, 200, 230, 255)), "item_vitality_gem.png")

    save(projectile((230, 120, 40, 255)), "proj_fireball.png")
    save(projectile((255, 230, 140, 255)), "proj_holybolt.png")
    save(arrow(), "proj_arrow.png")

    save(door(False), "door_closed.png")
    save(door(True), "door_open.png")
    save(icon(), "icon.png")

    gen_themes()
    print("done")


if __name__ == "__main__":
    main()
