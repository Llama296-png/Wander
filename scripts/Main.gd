extends Node2D
## Top-level orchestrator: shows the class-select screen, spawns the player
## and starting party, drives room-to-room transitions across a persistent
## room grid, and swaps in the HUD / game-over screen. This is the only node
## defined in a .tscn file -- everything else here is built at runtime.

const ClassData = preload("res://scripts/data/ClassData.gd")
const RoomGenerator = preload("res://scripts/world/RoomGenerator.gd")
const Room = preload("res://scripts/world/Room.gd")
const Player = preload("res://scripts/entities/Player.gd")
const Ally = preload("res://scripts/entities/Ally.gd")
const ClassSelectUI = preload("res://scripts/ui/ClassSelectUI.gd")
const HUD = preload("res://scripts/ui/HUD.gd")
const GameOverUI = preload("res://scripts/ui/GameOverUI.gd")

## World-space distance between grid cells. Every generated room is offset
## by its grid coordinate times this, so rooms that stay alive off-screen
## (persistence) never spatially overlap the one the player is standing in.
const CELL_SPACING := 900.0

var world: Node2D
## All rooms ever generated this run, keyed by grid coordinate -- kept alive
## (just hidden) so walking back through a door returns to the exact room
## you left, not a new one.
var rooms: Dictionary = {}
var current_coord: Vector2i = Vector2i.ZERO
var current_room: Room
var player: Node2D
var hud: HUD
var class_select: ClassSelectUI
var game_over_ui: GameOverUI


func _ready() -> void:
	world = Node2D.new()
	world.name = "World"
	add_child(world)

	GameManager.game_over.connect(_on_game_over)
	_show_class_select()


func _show_class_select() -> void:
	class_select = ClassSelectUI.new()
	add_child(class_select)
	class_select.class_chosen.connect(_on_class_chosen)


func _on_class_chosen(class_id: String, party_size: int, pacifist: bool) -> void:
	if is_instance_valid(class_select):
		class_select.queue_free()
	GameManager.start_new_run(class_id)
	GameManager.pacifist_mode = pacifist
	GameManager.desired_party_size = party_size

	for coord in rooms.keys():
		rooms[coord].queue_free()
	rooms.clear()
	current_room = null
	current_coord = Vector2i.ZERO

	player = Player.new()
	world.add_child(player)

	hud = HUD.new()
	add_child(hud)
	hud.set_player(player)

	_enter_room(Vector2i.ZERO, "south")
	_spawn_initial_party(party_size)


func _spawn_initial_party(count: int) -> void:
	var classes := ["warrior", "mage", "priest"]
	for i in range(count):
		if not GameManager.can_recruit():
			break
		classes.shuffle()
		_on_recruit(classes[0])


func _room_depth(coord: Vector2i) -> int:
	return abs(coord.x) + abs(coord.y) + 1


func _enter_room(coord: Vector2i, back_side: String) -> void:
	if is_instance_valid(current_room):
		current_room.set_active(false)

	var room: Room
	if rooms.has(coord):
		room = rooms[coord]
	else:
		var allowed_extra: Array = []
		for side in RoomGenerator.SIDES:
			if side == back_side:
				continue
			if not rooms.has(coord + RoomGenerator.DIR[side]):
				allowed_extra.append(side)
		var depth: int = _room_depth(coord)
		room = RoomGenerator.build(coord, back_side, depth, allowed_extra, GameManager.pacifist_mode)
		room.position = Vector2(coord.x, coord.y) * CELL_SPACING
		room.z_index = -100
		room.recruit_callback = Callable(self, "_on_recruit")
		room.door_entered.connect(_on_door_entered)
		add_child(room)
		rooms[coord] = room

	room.set_active(true)
	current_room = room
	current_coord = coord
	GameManager.enter_room_depth(_room_depth(coord))

	var spawn_pos: Vector2 = room.to_global(room.get_center())
	player.global_position = spawn_pos
	for ally in get_tree().get_nodes_in_group("ally"):
		ally.global_position = spawn_pos + ally.formation_offset


func _on_door_entered(side: String) -> void:
	var target_coord: Vector2i = current_coord + RoomGenerator.DIR[side]
	_enter_room(target_coord, RoomGenerator.OPPOSITE[side])


func _ally_formation_offset(index: int) -> Vector2:
	# First 6 allies ring close around the player, the rest form an outer
	# ring, so up to 10 allies can surround the player without stacking.
	var ring := 0 if index < 6 else 1
	var ring_index := index if ring == 0 else index - 6
	var ring_count := 6 if ring == 0 else 4
	var radius := 34.0 if ring == 0 else 60.0
	var angle := (float(ring_index) / float(ring_count)) * TAU
	return Vector2(cos(angle), sin(angle)) * radius


func _on_recruit(class_id: String) -> void:
	if not GameManager.can_recruit():
		return
	var stats := ClassData.ally_stats(class_id)
	var entry := GameManager.recruit_ally(class_id, stats)

	var ally := Ally.new()
	ally.class_id = class_id
	ally.ally_id = entry.id
	ally.formation_offset = _ally_formation_offset(GameManager.party.size() - 1)
	world.add_child(ally)
	ally.global_position = player.global_position + ally.formation_offset


func _on_game_over(depth_reached: int, score: int, xp_earned: int) -> void:
	game_over_ui = GameOverUI.new()
	add_child(game_over_ui)
	game_over_ui.show_result(depth_reached, score, xp_earned)
	game_over_ui.restart_requested.connect(_on_restart)


func _on_restart() -> void:
	game_over_ui.queue_free()
	if is_instance_valid(hud):
		hud.queue_free()
	for coord in rooms.keys():
		rooms[coord].queue_free()
	rooms.clear()
	current_room = null
	for ally in get_tree().get_nodes_in_group("ally"):
		ally.queue_free()
	if is_instance_valid(player):
		player.queue_free()
	_show_class_select()
