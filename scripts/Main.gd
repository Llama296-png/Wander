extends Node2D
## Top-level orchestrator: shows the class-select screen, spawns the player,
## drives room-to-room transitions, and swaps in the HUD / game-over screen.
## This is the only node defined in a .tscn file -- everything else here is
## built at runtime.

const ClassData = preload("res://scripts/data/ClassData.gd")
const RoomGenerator = preload("res://scripts/world/RoomGenerator.gd")
const Room = preload("res://scripts/world/Room.gd")
const Player = preload("res://scripts/entities/Player.gd")
const Ally = preload("res://scripts/entities/Ally.gd")
const ClassSelectUI = preload("res://scripts/ui/ClassSelectUI.gd")
const HUD = preload("res://scripts/ui/HUD.gd")
const GameOverUI = preload("res://scripts/ui/GameOverUI.gd")

var world: Node2D
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


func _on_class_chosen(class_id: String) -> void:
	class_select.queue_free()
	GameManager.start_new_run(class_id)

	player = Player.new()
	world.add_child(player)

	hud = HUD.new()
	add_child(hud)
	hud.set_player(player)

	_goto_room()


func _goto_room() -> void:
	if is_instance_valid(current_room):
		remove_child(current_room)
		current_room.queue_free()

	var room := RoomGenerator.build(GameManager.depth)
	room.z_index = -100
	room.recruit_callback = Callable(self, "_on_recruit")
	room.door_entered.connect(_on_door_entered)
	add_child(room)
	current_room = room

	var spawn_pos := room.get_center()
	player.global_position = spawn_pos
	for ally in get_tree().get_nodes_in_group("ally"):
		ally.global_position = spawn_pos + ally.formation_offset


func _on_door_entered(_side: String) -> void:
	GameManager.advance_depth()
	_goto_room()


func _on_recruit(class_id: String) -> void:
	if not GameManager.can_recruit():
		return
	var stats := ClassData.ally_stats(class_id)
	var entry := GameManager.recruit_ally(class_id, stats)

	var ally := Ally.new()
	ally.class_id = class_id
	ally.ally_id = entry.id
	ally.formation_offset = Vector2(-30, 24) if GameManager.party.size() <= 1 else Vector2(30, 24)
	world.add_child(ally)
	ally.global_position = player.global_position + ally.formation_offset


func _on_game_over(depth_reached: int, score: int) -> void:
	game_over_ui = GameOverUI.new()
	add_child(game_over_ui)
	game_over_ui.show_result(depth_reached, score)
	game_over_ui.restart_requested.connect(_on_restart)


func _on_restart() -> void:
	game_over_ui.queue_free()
	if is_instance_valid(hud):
		hud.queue_free()
	if is_instance_valid(current_room):
		current_room.queue_free()
	for ally in get_tree().get_nodes_in_group("ally"):
		ally.queue_free()
	if is_instance_valid(player):
		player.queue_free()
	_show_class_select()
