extends CharacterBody2D
## An AI-controlled party member that follows the player and fights nearby
## enemies. Persists across room transitions (created once on recruit).
## Set `class_id`, `ally_id` and `formation_offset` before `add_child()`.

const ClassData = preload("res://scripts/data/ClassData.gd")
const Projectile = preload("res://scripts/entities/Projectile.gd")

const AGGRO_RANGE := 220.0
const FOLLOW_STOP_DIST := 18.0
const HEAL_THRESHOLD := 0.6

var class_id: String = "warrior"
var ally_id: int = -1
var formation_offset: Vector2 = Vector2(-30, 24)

var stats: Dictionary
var max_hp: int
var hp: int
var damage: int
var speed: float
var melee_range: float

var _attack_cd: float = 0.0
var _ability_cd: float = 0.0
var _alive: bool = true
var sprite: Sprite2D
var _player: Node2D


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("ally")
	stats = ClassData.ally_stats(class_id)

	var s := Sprite2D.new()
	s.texture = load(stats.sprite_ally)
	s.scale = Vector2(1.8, 1.8)
	add_child(s)
	sprite = s

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	add_child(shape)

	collision_layer = 0
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)

	max_hp = stats.max_hp
	hp = max_hp
	damage = stats.damage
	speed = stats.speed
	melee_range = stats.get("melee_range", 20.0)

	_player = get_tree().get_first_node_in_group("player") as Node2D
	GameManager.update_ally_hp(ally_id, hp)


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_attack_cd = max(0.0, _attack_cd - delta)
	_ability_cd = max(0.0, _ability_cd - delta)

	if class_id == "priest" and _ability_cd <= 0.0 and _try_heal():
		return

	var target = _find_nearest_enemy()
	if target:
		var to_target: Vector2 = target.global_position - global_position
		var dist := to_target.length()
		var atk_range: float = melee_range if stats.attack_type == "melee" else stats.get("ability_radius", 160.0)
		if dist > atk_range * 0.85:
			velocity = to_target.normalized() * speed
		else:
			velocity = Vector2.ZERO
			if _attack_cd <= 0.0:
				_attack(target)
	else:
		_follow()

	if velocity.length() > 1.0:
		sprite.flip_h = velocity.x < 0
	move_and_slide()


func _follow() -> void:
	if not is_instance_valid(_player):
		velocity = Vector2.ZERO
		return
	var goal: Vector2 = _player.global_position + formation_offset
	var to_goal: Vector2 = goal - global_position
	if to_goal.length() > FOLLOW_STOP_DIST:
		velocity = to_goal.normalized() * speed
	else:
		velocity = Vector2.ZERO


func _find_nearest_enemy():
	var best = null
	var best_dist := AGGRO_RANGE
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var d: float = global_position.distance_to(enemy.global_position)
		if d < best_dist:
			best_dist = d
			best = enemy
	return best


func _attack(target) -> void:
	_attack_cd = stats.attack_cooldown
	if stats.attack_type == "melee":
		target.take_damage(damage, global_position)
	else:
		var proj := Projectile.new()
		var dir: Vector2 = (target.global_position - global_position).normalized()
		proj.direction = dir
		proj.speed = stats.projectile_speed
		proj.damage = damage
		proj.sprite_path = stats.projectile_sprite
		proj.is_enemy_projectile = false
		proj.global_position = global_position + dir * 12.0
		get_parent().add_child(proj)


func _try_heal() -> bool:
	var lowest = null
	var lowest_ratio := HEAL_THRESHOLD
	var candidates: Array = get_tree().get_nodes_in_group("ally") + get_tree().get_nodes_in_group("player")
	for c in candidates:
		if not c.has_method("heal"):
			continue
		var ratio: float = float(c.hp) / float(c.max_hp)
		if ratio < lowest_ratio and global_position.distance_to(c.global_position) <= stats.ability_radius:
			lowest_ratio = ratio
			lowest = c
	if lowest:
		_ability_cd = stats.ability_cooldown
		lowest.heal(stats.ability_heal)
		return true
	return false


func heal(amount: int) -> void:
	if not _alive:
		return
	hp = min(max_hp, hp + amount)
	GameManager.update_ally_hp(ally_id, hp)


func take_damage(amount: int, _from_pos: Vector2 = Vector2.ZERO) -> void:
	if not _alive:
		return
	hp = max(0, hp - amount)
	GameManager.update_ally_hp(ally_id, hp)
	_flash()
	if hp <= 0:
		die()


func _flash() -> void:
	sprite.modulate = Color(1, 0.5, 0.5)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(1, 1, 1), 0.15)


func die() -> void:
	if not _alive:
		return
	_alive = false
	GameManager.remove_ally(ally_id)
	queue_free()
