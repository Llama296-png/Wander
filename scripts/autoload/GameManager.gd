extends Node
## Global game state: run progress, party roster, inventory and score.
## Autoloaded as "GameManager". Persistent meta-progression (class XP/levels/
## unlocks) lives in the separate SaveManager autoload.

const PersonalityData = preload("res://scripts/data/PersonalityData.gd")

signal depth_changed(depth: int)
signal score_changed(score: int)
signal inventory_changed
signal party_changed
signal game_over(depth_reached: int, score: int, xp_earned: int)

var rng := RandomNumberGenerator.new()

var player_class_id: String = "warrior"
var score: int = 0

## Depth of the room the player is currently standing in (Manhattan distance
## from the starting room, 1-based). Can go back down when backtracking.
var depth: int = 1
## Deepest room depth reached this run -- monotonic, used for the game-over
## summary and for the XP awarded at the end of the run.
var max_depth_reached: int = 1

var pacifist_mode: bool = false
## How many allies to start the run with, chosen at class select (0-10).
var desired_party_size: int = 0

## Ally data for the current run, keyed by a unique instance id.
## Each entry: {id, class_id, hp, max_hp, personality_id}
var party: Array = []
var _next_ally_id: int = 0

const MAX_PARTY_SIZE := 10
const MAX_INVENTORY_SLOTS := 4

## Inventory slots: [{id: String, count: int}, ...]
var inventory: Array = []

## Permanent (per-run) bonuses gathered from instant pickups.
var bonus_damage_mult: float = 1.0
var bonus_max_hp: int = 0


func _ready() -> void:
	rng.randomize()


func start_new_run(class_id: String) -> void:
	player_class_id = class_id
	depth = 1
	max_depth_reached = 1
	score = 0
	party.clear()
	inventory.clear()
	bonus_damage_mult = 1.0
	bonus_max_hp = 0
	inventory_changed.emit()
	party_changed.emit()
	score_changed.emit(score)
	depth_changed.emit(depth)


func enter_room_depth(new_depth: int) -> void:
	depth = new_depth
	max_depth_reached = max(max_depth_reached, new_depth)
	depth_changed.emit(depth)


func difficulty_mult_for_depth(d: int) -> float:
	return 1.0 + float(d - 1) * 0.18


func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)


func report_game_over() -> void:
	var xp_earned := max_depth_reached * 8 + int(score / 2.0)
	SaveManager.add_run_xp(player_class_id, xp_earned)
	game_over.emit(max_depth_reached, score, xp_earned)


func can_recruit() -> bool:
	return party.size() < MAX_PARTY_SIZE


func recruit_ally(class_id: String, stats: Dictionary) -> Dictionary:
	var entry := {
		"id": _next_ally_id,
		"class_id": class_id,
		"hp": stats.max_hp,
		"max_hp": stats.max_hp,
		"personality_id": PersonalityData.random_id(rng),
	}
	_next_ally_id += 1
	party.append(entry)
	party_changed.emit()
	return entry


func remove_ally(ally_id: int) -> void:
	for i in range(party.size()):
		if party[i].id == ally_id:
			party.remove_at(i)
			party_changed.emit()
			return


func update_ally_hp(ally_id: int, hp: int) -> void:
	for entry in party:
		if entry.id == ally_id:
			entry.hp = hp
			party_changed.emit()
			return


func add_item(item_id: String, count: int = 1) -> bool:
	for slot in inventory:
		if slot.id == item_id:
			slot.count += count
			inventory_changed.emit()
			return true
	if inventory.size() < MAX_INVENTORY_SLOTS:
		inventory.append({"id": item_id, "count": count})
		inventory_changed.emit()
		return true
	return false


func use_item_slot(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= inventory.size():
		return ""
	var slot: Dictionary = inventory[slot_index]
	var item_id: String = slot.id
	slot.count -= 1
	if slot.count <= 0:
		inventory.remove_at(slot_index)
	inventory_changed.emit()
	return item_id
