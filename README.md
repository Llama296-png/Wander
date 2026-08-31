# Wander

A 2D pixel-art roguelike built in Godot. Fight through procedurally
generated rooms, with difficulty escalating the deeper you go.

## Running it

1. Install [Godot 4.7+](https://godotengine.org/download) (the standard,
   non-.NET build). The project targets Godot 4.7 but only uses long-stable
   Godot 4.x APIs, so it should also open fine on 4.3-4.6.
2. Open Godot, choose **Import**, and select this repo's `project.godot`.
3. Press **F5** (or the Play button) to run.

## How to play

- **Move**: WASD / arrow keys
- **Attack**: Left click or `J` (aims at your mouse cursor)
- **Ability**: `Space` or `K`
- **Use item**: `1`-`4`

Pick a class at the title screen -- Warrior (melee bruiser), Mage (ranged
AoE nuker), or Priest (ranged support/healer) -- then fight your way through
each room. Clearing a room unlocks its doors; walking through one generates
a brand new room one floor deeper, with tougher and more varied enemies.
Cleared rooms sometimes leave behind a rescuable ally who will follow you
and fight automatically. Defeated enemies sometimes drop gold, permanent
stat gems, or potions (stored in your 4-slot inventory).

## Project layout

- `scenes/Main.tscn` -- the only hand-authored scene; everything else
  (rooms, characters, UI) is built at runtime from GDScript so there are no
  other `.tscn` files to keep in sync.
- `scripts/autoload/GameManager.gd` -- global run state (class, depth,
  party, inventory, score).
- `scripts/data/` -- static class/item tables.
- `scripts/entities/` -- Player, Ally, Enemy, Projectile, Item, RecruitPickup.
- `scripts/world/` -- Room + RoomGenerator (procedural generation).
- `scripts/ui/` -- class select, HUD, game over screens.
- `assets/sprites/` -- generated 16x16 pixel art (see `tools/gen_art.py`).
- `tools/gen_art.py` -- regenerates all sprites (`python3 tools/gen_art.py`,
  requires Pillow).
