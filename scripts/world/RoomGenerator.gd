extends Node
## Builds a randomized Room configuration for a spot on the room grid.
## Pure logic -- returns an unparented, configured Room node ready for the
## caller to `add_child()` (which triggers Room._ready() to build geometry).
## The room grid itself (which coords have been generated, how they connect)
## is owned by Main -- this only knows how to build ONE room given the facts
## Main hands it, so rooms persist and always connect back the way you came.

const Room = preload("res://scripts/world/Room.gd")
const RoomThemeData = preload("res://scripts/data/RoomThemeData.gd")

const SIDES := ["north", "south", "east", "west"]
const DIR := {
	"north": Vector2i(0, -1),
	"south": Vector2i(0, 1),
	"east": Vector2i(1, 0),
	"west": Vector2i(-1, 0),
}
const OPPOSITE := {"north": "south", "south": "north", "east": "west", "west": "east"}


## coord: this room's grid position. back_side: the side that must have a
## door leading back to where the player came from (ignored for the very
## first room). depth: 1-based distance-from-start used for enemy scaling.
## allowed_extra_sides: sides Main has determined are safe to put an extra
## door on (their neighboring cell doesn't already exist without one).
static func build(coord: Vector2i, back_side: String, depth: int, allowed_extra_sides: Array, pacifist_mode: bool) -> Room:
	var rng := GameManager.rng

	var width_tiles := rng.randi_range(12, 17)
	var height_tiles := rng.randi_range(8, 11)

	var door_sides: Array = [back_side]
	var extra_pool: Array = allowed_extra_sides.duplicate()
	extra_pool.shuffle()
	var extra_count := rng.randi_range(0, 2)
	for i in range(min(extra_count, extra_pool.size())):
		door_sides.append(extra_pool[i])

	var enemy_types := ["slime"]
	if depth >= 3:
		enemy_types.append("bat")
	if depth >= 5:
		enemy_types.append("skeleton")
	if depth >= 7:
		enemy_types.append("brute")

	var enemy_count := 0
	if coord != Vector2i.ZERO and not pacifist_mode:
		enemy_count = clampi(2 + int(depth / 2.0) + rng.randi_range(-1, 1), 1, 9)

	var room := Room.new()
	room.width_tiles = width_tiles
	room.height_tiles = height_tiles
	room.door_sides = door_sides
	room.enemy_types = enemy_types
	room.enemy_count = enemy_count
	room.depth = depth
	room.difficulty_mult = GameManager.difficulty_mult_for_depth(depth)
	room.pacifist_mode = pacifist_mode
	room.theme_id = RoomThemeData.random_id(rng)
	return room
