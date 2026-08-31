extends Node
## Builds a randomized Room configuration for a given dungeon depth.
## Pure logic -- returns an unparented, configured Room node ready for the
## caller to `add_child()` (which triggers Room._ready() to build geometry).

const Room = preload("res://scripts/world/Room.gd")

const SIDES := ["north", "south", "east", "west"]


static func build(depth: int) -> Room:
	var rng := GameManager.rng

	var width_tiles := rng.randi_range(12, 17)
	var height_tiles := rng.randi_range(8, 11)

	var door_sides: Array = []
	var shuffled := SIDES.duplicate()
	shuffled.shuffle()
	var door_count := rng.randi_range(1, 3) if depth > 1 else 1
	for i in range(door_count):
		door_sides.append(shuffled[i])

	var enemy_types := ["slime"]
	if depth >= 3:
		enemy_types.append("bat")
	if depth >= 5:
		enemy_types.append("skeleton")
	if depth >= 7:
		enemy_types.append("brute")

	var enemy_count := 0
	if depth > 1:
		enemy_count = clampi(2 + int(depth / 2.0) + rng.randi_range(-1, 1), 1, 9)

	var room := Room.new()
	room.width_tiles = width_tiles
	room.height_tiles = height_tiles
	room.door_sides = door_sides
	room.enemy_types = enemy_types
	room.enemy_count = enemy_count
	room.depth = depth
	room.difficulty_mult = GameManager.get_difficulty_mult()
	return room
