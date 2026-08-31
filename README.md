# Wander

A 2D pixel-art roguelike built in Godot. Fight (or sneak) through a
persistent, procedurally generated house, with difficulty escalating the
further you get from the entrance.

## Running it

1. Install [Godot 4.7+](https://godotengine.org/download) (the standard,
   non-.NET build). The project targets Godot 4.7 but only uses long-stable
   Godot 4.x APIs, so it should also open fine on 4.3-4.6.
2. Open Godot, choose **Import**, and select this repo's `project.godot`.
3. Press **F5** (or the Play button) to run.

## How to play

- **Move**: WASD / arrow keys
- **Attack**: Left click or `J` -- you (and your weapon) always face the
  mouse cursor
- **Ability**: `Space` or `K`
- **Use item**: `1`-`4`

At the title screen, pick a class -- Warrior (melee bruiser), Mage (ranged
AoE nuker), or Priest (ranged support/healer). Mage and Priest start locked
and unlock once you've earned enough class XP from past runs; each class
also levels up (to 5) from its own accumulated XP, for small permanent stat
bonuses. You also choose how many allies to bring (0-10, each with a random
personality that tweaks how aggressively/cautiously it fights) and whether
to play in **Pacifist Mode**, where room doors unlock without needing to
kill anything in them.

The house is laid out on a persistent grid: each room is one of six themes
(bathroom, living room, garage, bedroom, master bedroom, kitchen) with
matching floor/wall art and furniture. Clearing a room (or just being in
pacifist mode) unlocks its doors; walking through one either generates a
brand new room one step further from the start (tougher, more varied
enemies) or, if you're backtracking, returns you to the exact room you left
-- nothing regenerates. Rescued/recruited allies follow you and fight (or
heal, for priests) automatically. Defeated enemies sometimes drop gold,
permanent stat gems, or potions (stored in your 4-slot inventory). Dying
shows how much class XP you earned and returns you to the title screen,
where that progress has already been saved.

## Project layout

- `scenes/Main.tscn` -- the only hand-authored scene; everything else
  (rooms, characters, UI) is built at runtime from GDScript so there are no
  other `.tscn` files to keep in sync.
- `scripts/autoload/GameManager.gd` -- per-run state (class, party,
  inventory, score, pacifist mode).
- `scripts/autoload/SaveManager.gd` -- persistent meta-progression (class
  XP/levels/unlocks), saved to a small JSON file in the user's save
  directory.
- `scripts/data/` -- static class/item/personality/room-theme tables.
- `scripts/entities/` -- Player, Ally, Enemy, Projectile, Item,
  RecruitPickup, and `AnimSetup.gd` (builds each actor's SpriteFrames from
  its idle/walk/attack/death animation frames).
- `scripts/world/` -- Room (geometry, theme, props, enemies) + RoomGenerator
  (builds one room for a spot on the persistent room grid).
- `scripts/ui/` -- class select (with party-size/pacifist controls), HUD,
  game over screen.
- `assets/sprites/` -- generated pixel art, including per-animation-frame
  actor sprites and per-theme floor/wall/prop art (see `tools/gen_art.py`).
- `tools/gen_art.py` -- regenerates all sprites (`python3 tools/gen_art.py`,
  requires Pillow).
