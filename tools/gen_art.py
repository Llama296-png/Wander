#!/usr/bin/env python3
"""Generates the 16x16 pixel-art sprite sheet for Wander.

Run with `python3 gen_art.py` from anywhere; writes PNGs into
../assets/sprites relative to this file. Kept in the repo so the art can be
regenerated or tweaked later without hand-editing pixels.
"""
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
os.makedirs(OUT, exist_ok=True)

OUTLINE = (24, 18, 26, 255)
SHADOW = (20, 16, 24, 130)


def canvas():
    return Image.new("RGBA", (16, 16), (0, 0, 0, 0))


def save(img, name):
    img.save(os.path.join(OUT, name))
    print("wrote", name)


def humanoid(body, skin, accent, weapon):
    img = canvas()
    d = ImageDraw.Draw(img)
    d.ellipse([4, 13, 12, 15], fill=SHADOW)
    d.polygon([(4, 6), (11, 6), (13, 14), (2, 14)], fill=body, outline=OUTLINE)
    d.ellipse([4, 1, 11, 8], fill=skin, outline=OUTLINE)
    d.point((6, 4), fill=OUTLINE)
    d.point((9, 4), fill=OUTLINE)
    d.line([(3, 10), (12, 10)], fill=accent, width=1)
    if weapon == "sword":
        d.line([(12, 4), (15, 1)], fill=(210, 210, 220, 255), width=1)
        d.point((12, 4), fill=accent)
    elif weapon == "staff":
        d.line([(12, 2), (13, 15)], fill=(120, 80, 44, 255), width=1)
        d.ellipse([11, 0, 14, 3], fill=accent, outline=OUTLINE)
    elif weapon == "symbol":
        d.line([(13, 1), (13, 6)], fill=accent, width=1)
        d.line([(11, 3), (15, 3)], fill=accent, width=1)
    return img


def slime(color):
    img = canvas()
    d = ImageDraw.Draw(img)
    d.ellipse([3, 12, 13, 15], fill=SHADOW)
    d.ellipse([2, 6, 14, 15], fill=color, outline=OUTLINE)
    d.ellipse([4, 8, 7, 10], fill=(255, 255, 255, 110))
    d.point((6, 11), fill=OUTLINE)
    d.point((10, 11), fill=OUTLINE)
    return img


def bat(color):
    img = canvas()
    d = ImageDraw.Draw(img)
    d.polygon([(1, 6), (5, 8), (2, 12)], fill=color, outline=OUTLINE)
    d.polygon([(15, 6), (11, 8), (14, 12)], fill=color, outline=OUTLINE)
    d.ellipse([5, 5, 11, 12], fill=color, outline=OUTLINE)
    d.point((7, 8), fill=(230, 40, 60, 255))
    d.point((9, 8), fill=(230, 40, 60, 255))
    return img


def skeleton():
    img = canvas()
    bone = (232, 226, 210, 255)
    d = ImageDraw.Draw(img)
    d.ellipse([4, 13, 12, 15], fill=SHADOW)
    d.polygon([(4, 7), (11, 7), (12, 14), (3, 14)], fill=bone, outline=OUTLINE)
    d.ellipse([4, 1, 11, 8], fill=bone, outline=OUTLINE)
    d.point((6, 4), fill=(20, 20, 24, 255))
    d.point((9, 4), fill=(20, 20, 24, 255))
    d.line([(6, 10), (9, 10)], fill=OUTLINE)
    d.line([(2, 10), (13, 4)], fill=(200, 190, 170, 255), width=1)
    return img


def brute(color):
    img = canvas()
    d = ImageDraw.Draw(img)
    d.ellipse([2, 13, 14, 15], fill=SHADOW)
    d.polygon([(2, 5), (13, 5), (15, 14), (0, 14)], fill=color, outline=OUTLINE)
    d.ellipse([3, 0, 12, 7], fill=(200, 160, 120, 255), outline=OUTLINE)
    d.point((5, 3), fill=OUTLINE)
    d.point((10, 3), fill=OUTLINE)
    d.line([(1, 9), (14, 9)], fill=(90, 40, 30, 255), width=1)
    return img


def potion(liquid):
    img = canvas()
    d = ImageDraw.Draw(img)
    d.rectangle([6, 2, 9, 4], fill=(150, 150, 160, 255), outline=OUTLINE)
    d.ellipse([4, 5, 11, 14], fill=(230, 240, 250, 200), outline=OUTLINE)
    d.ellipse([5, 7, 10, 13], fill=liquid)
    d.point((6, 8), fill=(255, 255, 255, 180))
    return img


def gold_coin():
    img = canvas()
    d = ImageDraw.Draw(img)
    d.ellipse([3, 3, 12, 12], fill=(255, 205, 60, 255), outline=(150, 100, 10, 255))
    d.ellipse([5, 5, 10, 10], fill=(255, 230, 120, 255))
    return img


def gem(color):
    img = canvas()
    d = ImageDraw.Draw(img)
    d.polygon([(8, 2), (13, 7), (8, 14), (3, 7)], fill=color, outline=OUTLINE)
    d.polygon([(8, 2), (10, 7), (8, 14), (6, 7)], fill=(255, 255, 255, 90))
    return img


def projectile(color):
    img = canvas()
    d = ImageDraw.Draw(img)
    d.ellipse([5, 5, 11, 11], fill=color, outline=OUTLINE)
    d.ellipse([6, 6, 9, 9], fill=(255, 255, 255, 160))
    return img


def arrow():
    img = canvas()
    d = ImageDraw.Draw(img)
    d.line([(2, 8), (13, 8)], fill=(150, 110, 70, 255), width=2)
    d.polygon([(13, 5), (15, 8), (13, 11)], fill=(200, 200, 210, 255), outline=OUTLINE)
    d.line([(2, 6), (4, 8)], fill=(220, 60, 60, 255), width=1)
    d.line([(2, 10), (4, 8)], fill=(220, 60, 60, 255), width=1)
    return img


def floor_tile():
    img = canvas()
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 15, 15], fill=(58, 50, 62, 255))
    for (x, y) in [(2, 2), (9, 3), (4, 9), (11, 11), (6, 6)]:
        d.point((x, y), fill=(70, 61, 75, 255))
    d.line([(0, 0), (15, 0)], fill=(64, 55, 68, 255))
    d.line([(0, 0), (0, 15)], fill=(64, 55, 68, 255))
    return img


def wall_tile():
    img = canvas()
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 15, 15], fill=(38, 32, 44, 255))
    d.rectangle([0, 0, 15, 6], fill=(90, 78, 92, 255), outline=OUTLINE)
    d.line([(0, 3), (15, 3)], fill=(70, 60, 72, 255))
    d.rectangle([0, 7, 15, 15], fill=(46, 38, 50, 255), outline=OUTLINE)
    d.line([(0, 11), (15, 11)], fill=(56, 47, 60, 255))
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
    d.rectangle([0, 0, 15, 15], fill=(58, 50, 62, 255))
    img.alpha_composite(humanoid((90, 140, 210, 255), (235, 200, 165, 255), (230, 200, 90, 255), "sword"))
    return img


save(humanoid((90, 110, 200, 255), (235, 200, 165, 255), (210, 210, 220, 255), "sword"), "player_warrior.png")
save(humanoid((150, 70, 200, 255), (235, 200, 165, 255), (90, 220, 230, 255), "staff"), "player_mage.png")
save(humanoid((235, 225, 200, 255), (235, 200, 165, 255), (255, 210, 90, 255), "symbol"), "player_priest.png")

save(humanoid((70, 90, 160, 255), (225, 190, 155, 255), (180, 180, 190, 255), "sword"), "ally_warrior.png")
save(humanoid((120, 55, 160, 255), (225, 190, 155, 255), (70, 190, 200, 255), "staff"), "ally_mage.png")
save(humanoid((205, 195, 175, 255), (225, 190, 155, 255), (225, 180, 70, 255), "symbol"), "ally_priest.png")

save(slime((70, 200, 110, 255)), "enemy_slime.png")
save(bat((60, 50, 70, 255)), "enemy_bat.png")
save(skeleton(), "enemy_skeleton.png")
save(brute((170, 60, 50, 255)), "enemy_brute.png")

save(potion((220, 60, 90, 255)), "item_potion.png")
save(potion((230, 60, 220, 255)), "item_mega_potion.png")
save(gold_coin(), "item_gold.png")
save(gem((230, 90, 90, 255)), "item_power_gem.png")
save(gem((90, 200, 230, 255)), "item_vitality_gem.png")

save(projectile((230, 120, 40, 255)), "proj_fireball.png")
save(projectile((255, 230, 140, 255)), "proj_holybolt.png")
save(arrow(), "proj_arrow.png")

save(floor_tile(), "tile_floor.png")
save(wall_tile(), "tile_wall.png")
save(door(False), "door_closed.png")
save(door(True), "door_open.png")

save(icon(), "icon.png")

print("done")
