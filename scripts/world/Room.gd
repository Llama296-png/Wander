extends Node2D
## A single procedurally-built room: floor, perimeter walls with door gaps,
## a themed set of decorative/blocking props, enemies scaled to depth, and
## item/ally drops. Configure the exported-style fields below before
## `add_child()`; geometry and enemies are built in `_ready()`. Rooms persist
## once built -- Main shows/hides them rather than recreating them, so all
## state here (enemy hp, dropped items, unlocked doors, ...) sticks around
## exactly as the player left it.

const Enemy = preload("res://scripts/entities/Enemy.gd")
const Item = preload("res://scripts/entities/Item.gd")
const RecruitPickup = preload("res://scripts/entities/RecruitPickup.gd")
const ItemData = preload("res://scripts/data/ItemData.gd")
const RoomThemeData = preload("res://scripts/data/RoomThemeData.gd")

const TILE := 32
const WALL_THICK := 32
const DOOR_GAP := 72.0
const TYPE_WEIGHTS := {"slime": 5, "bat": 4, "skeleton": 3, "brute": 1}

signal door_entered(side: String)

# --- configuration, set before add_child() ---
var width_tiles: int = 14
var height_tiles: int = 9
var door_sides: Array = ["south"]
var enemy_types: Array = ["slime"]
var enemy_count: int = 2
var depth: int = 1
var difficulty_mult: float = 1.0
var pacifist_mode: bool = false
var theme_id: String = ""
var recruit_callback: Callable = Callable()

# --- runtime ---
var width_px: float
var height_px: float
var _alive_enemies: int = 0
var _doors: Dictionary = {}
var _recruit_spawned: bool = false
var _theme: Dictionary


func _ready() -> void:
	width_px = width_tiles * TILE
	height_px = height_tiles * TILE
	if theme_id == "":
		theme_id = RoomThemeData.random_id(GameManager.rng)
	_theme = RoomThemeData.get_theme(theme_id)

	_build_floor()
	_build_walls_and_doors()
	_place_props()
	_spawn_enemies()
	if _alive_enemies == 0 or pacifist_mode:
		_unlock_all()


func get_center() -> Vector2:
	return Vector2(width_px / 2.0, height_px / 2.0)


func set_active(active: bool) -> void:
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED


func _build_floor() -> void:
	var floor_sprite := Sprite2D.new()
	floor_sprite.texture = load(_theme.floor)
	floor_sprite.centered = false
	floor_sprite.region_enabled = true
	floor_sprite.region_rect = Rect2(0, 0, width_tiles * 16, height_tiles * 16)
	floor_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	floor_sprite.scale = Vector2(2, 2)
	floor_sprite.z_index = -10
	add_child(floor_sprite)


func _make_wall(rect_px: Rect2) -> void:
	if rect_px.size.x <= 0.0 or rect_px.size.y <= 0.0:
		return
	var wall_sprite := Sprite2D.new()
	wall_sprite.texture = load(_theme.wall)
	wall_sprite.centered = false
	wall_sprite.region_enabled = true
	wall_sprite.region_rect = Rect2(0, 0, rect_px.size.x / 2.0, rect_px.size.y / 2.0)
	wall_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	wall_sprite.scale = Vector2(2, 2)
	wall_sprite.position = rect_px.position
	add_child(wall_sprite)

	var body := StaticBody2D.new()
	body.position = rect_px.position + rect_px.size / 2.0
	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = rect_px.size
	shape.shape = rect_shape
	body.add_child(shape)
	body.set_collision_layer_value(1, true)
	add_child(body)


func _build_walls_and_doors() -> void:
	var has_door := {}
	for s in door_sides:
		has_door[s] = true

	# North / south walls span the full width (they cover the corners).
	_build_side_wall("north", has_door.has("north"), Vector2(0, 0), Vector2(width_px, WALL_THICK), true)
	_build_side_wall("south", has_door.has("south"), Vector2(0, height_px - WALL_THICK), Vector2(width_px, WALL_THICK), true)
	# East / west walls only span the interior band between the top/bottom walls.
	_build_side_wall("west", has_door.has("west"), Vector2(0, WALL_THICK), Vector2(WALL_THICK, height_px - WALL_THICK * 2), false)
	_build_side_wall("east", has_door.has("east"), Vector2(width_px - WALL_THICK, WALL_THICK), Vector2(WALL_THICK, height_px - WALL_THICK * 2), false)


func _build_side_wall(side: String, has_door: bool, origin: Vector2, size: Vector2, horizontal: bool) -> void:
	if not has_door:
		_make_wall(Rect2(origin, size))
		return

	var gap_center: float
	var door_pos: Vector2
	if horizontal:
		gap_center = origin.x + size.x / 2.0
		_make_wall(Rect2(origin, Vector2(gap_center - DOOR_GAP / 2.0 - origin.x, size.y)))
		_make_wall(Rect2(Vector2(gap_center + DOOR_GAP / 2.0, origin.y), Vector2(origin.x + size.x - (gap_center + DOOR_GAP / 2.0), size.y)))
		door_pos = Vector2(gap_center, origin.y + size.y / 2.0)
	else:
		gap_center = origin.y + size.y / 2.0
		_make_wall(Rect2(origin, Vector2(size.x, gap_center - DOOR_GAP / 2.0 - origin.y)))
		_make_wall(Rect2(Vector2(origin.x, gap_center + DOOR_GAP / 2.0), Vector2(size.x, origin.y + size.y - (gap_center + DOOR_GAP / 2.0))))
		door_pos = Vector2(origin.x + size.x / 2.0, gap_center)

	_build_door(side, door_pos, horizontal)


func _build_door(side: String, pos: Vector2, horizontal: bool) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/sprites/door_closed.png")
	sprite.scale = Vector2(DOOR_GAP / 16.0, float(WALL_THICK) / 16.0) if horizontal else Vector2(float(WALL_THICK) / 16.0, DOOR_GAP / 16.0)
	sprite.position = pos
	add_child(sprite)

	var blocker := StaticBody2D.new()
	blocker.position = pos
	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(DOOR_GAP, WALL_THICK) if horizontal else Vector2(WALL_THICK, DOOR_GAP)
	shape.shape = rect_shape
	blocker.add_child(shape)
	blocker.set_collision_layer_value(1, true)
	add_child(blocker)

	var area := Area2D.new()
	area.position = pos
	var area_shape := CollisionShape2D.new()
	var area_rect := RectangleShape2D.new()
	area_rect.size = Vector2(DOOR_GAP, WALL_THICK + 24.0) if horizontal else Vector2(WALL_THICK + 24.0, DOOR_GAP)
	area_shape.shape = area_rect
	area.add_child(area_shape)
	area.collision_layer = 0
	area.set_collision_mask_value(2, true)
	area.monitoring = true
	area.monitorable = false
	add_child(area)
	area.body_entered.connect(_on_door_body_entered.bind(side))

	_doors[side] = {"locked": true, "sprite": sprite, "blocker": blocker}


func _on_door_body_entered(body: Node2D, side: String) -> void:
	if not body.is_in_group("player"):
		return
	if _doors[side].locked:
		return
	# Deferred: this fires from inside the physics server's query flush (a
	# body_entered callback), and the room transition this triggers builds a
	# whole new room's worth of physics bodies -- which Godot refuses to do
	# until the current physics step finishes flushing.
	call_deferred("emit_signal", "door_entered", side)


func _unlock_all() -> void:
	for side in _doors.keys():
		var d: Dictionary = _doors[side]
		if not d.locked:
			continue
		d.locked = false
		d.sprite.texture = load("res://assets/sprites/door_open.png")
		if is_instance_valid(d.blocker):
			d.blocker.queue_free()
	_maybe_spawn_recruit()


func _place_props() -> void:
	var props: Array = _theme.get("props", [])
	if props.is_empty():
		return
	var rng := GameManager.rng
	var count := rng.randi_range(1, min(2, props.size()))
	var shuffled: Array = props.duplicate()
	shuffled.shuffle()
	var center := get_center()
	var margin := WALL_THICK + 24.0
	var placed: Array = []
	for i in range(count):
		var tex := load(shuffled[i])
		var half_size: Vector2 = Vector2(tex.get_size()) * 1.5
		var pos := Vector2.ZERO
		var ok := false
		for attempt in range(12):
			pos = Vector2(
				rng.randf_range(margin + half_size.x, width_px - margin - half_size.x),
				rng.randf_range(margin + half_size.y, height_px - margin - half_size.y)
			)
			if pos.distance_to(center) < 60.0:
				continue
			ok = true
			for other in placed:
				if pos.distance_to(other) < 70.0:
					ok = false
					break
			if ok:
				break
		if not ok:
			continue
		placed.append(pos)

		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.scale = Vector2(2, 2)
		sprite.position = pos
		add_child(sprite)

		var body := StaticBody2D.new()
		body.position = pos
		var shape := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = Vector2(tex.get_size()) * 1.7
		shape.shape = rect_shape
		body.add_child(shape)
		body.set_collision_layer_value(1, true)
		add_child(body)


func _spawn_enemies() -> void:
	var rng := GameManager.rng
	var center := get_center()
	var margin := WALL_THICK + 20.0
	for i in range(enemy_count):
		var etype := _pick_enemy_type(rng)
		var enemy := Enemy.new()
		enemy.enemy_type = etype
		enemy.difficulty_mult = difficulty_mult
		enemy.on_death = Callable(self, "_on_enemy_died")
		enemy.spawn_item = Callable(self, "_spawn_item_at")

		var pos := Vector2.ZERO
		for attempt in range(10):
			pos = Vector2(
				rng.randf_range(margin, width_px - margin),
				rng.randf_range(margin, height_px - margin)
			)
			if pos.distance_to(center) > 70.0:
				break
		enemy.position = pos
		add_child(enemy)
		_alive_enemies += 1


func _pick_enemy_type(rng: RandomNumberGenerator) -> String:
	var total := 0
	for t in enemy_types:
		total += TYPE_WEIGHTS.get(t, 1)
	var roll := rng.randi_range(0, total - 1)
	var acc := 0
	for t in enemy_types:
		acc += TYPE_WEIGHTS.get(t, 1)
		if roll < acc:
			return t
	return enemy_types[0]


func _on_enemy_died() -> void:
	_alive_enemies -= 1
	if _alive_enemies <= 0:
		_unlock_all()


func _spawn_item_at(pos: Vector2) -> void:
	var rng := GameManager.rng
	if rng.randf() > 0.55:
		return
	var item := Item.new()
	item.item_id = ItemData.roll_drop(rng)
	item.position = pos
	add_child(item)


func _maybe_spawn_recruit() -> void:
	if _recruit_spawned or not recruit_callback.is_valid():
		return
	if not GameManager.can_recruit():
		return
	if GameManager.rng.randf() > 0.35:
		return
	_recruit_spawned = true
	var classes := ["warrior", "mage", "priest"]
	classes.shuffle()
	var recruit := RecruitPickup.new()
	recruit.class_id = classes[0]
	recruit.on_recruited = recruit_callback
	recruit.position = get_center() + Vector2(GameManager.rng.randf_range(-40, 40), GameManager.rng.randf_range(-40, 40))
	add_child(recruit)
