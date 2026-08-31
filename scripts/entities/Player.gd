extends CharacterBody2D
## The player-controlled hero. Stats and abilities come from ClassData based
## on `GameManager.player_class_id`. All child nodes are built in `_ready()`
## so the entity needs no companion .tscn file.

const ClassData = preload("res://scripts/data/ClassData.gd")
const ItemData = preload("res://scripts/data/ItemData.gd")
const Projectile = preload("res://scripts/entities/Projectile.gd")
const AnimSetup = preload("res://scripts/entities/AnimSetup.gd")

const ATTACK_ANIM_TIME := 0.3

signal hp_changed(hp: int, max_hp: int)
signal ability_ready_changed(ratio: float)
signal died

var stats: Dictionary
var max_hp: int
var hp: int
var damage: int
var speed: float

var facing: Vector2 = Vector2.RIGHT
var _attack_cd: float = 0.0
var _ability_cd: float = 0.0
var _attack_anim_timer: float = 0.0
var _alive: bool = true

var sprite: AnimatedSprite2D


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")
	stats = ClassData.get_stats(GameManager.player_class_id)

	var s := AnimatedSprite2D.new()
	s.sprite_frames = AnimSetup.build(stats.anim_prefix)
	s.play("idle")
	s.scale = Vector2(1.5, 1.5)
	add_child(s)
	sprite = s

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 11.0
	shape.shape = circle
	add_child(shape)

	collision_layer = 0
	set_collision_layer_value(2, true)
	set_collision_mask_value(1, true)

	var camera := Camera2D.new()
	camera.zoom = Vector2(1, 1)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	add_child(camera)

	var level_mult: float = SaveManager.level_stat_mult(GameManager.player_class_id)
	max_hp = int((stats.max_hp + GameManager.bonus_max_hp) * level_mult)
	hp = max_hp
	damage = int(stats.damage * GameManager.bonus_damage_mult * level_mult)
	speed = stats.speed


func apply_stat_bonus(hp_bonus: int, dmg_mult_bonus: float) -> void:
	if hp_bonus > 0:
		max_hp += hp_bonus
		hp = min(hp + hp_bonus, max_hp)
	if dmg_mult_bonus > 0.0:
		damage = int(damage * (1.0 + dmg_mult_bonus))
	hp_changed.emit(hp, max_hp)


func _physics_process(delta: float) -> void:
	if not _alive:
		return

	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vec * speed
	move_and_slide()

	if input_vec.length() > 0.1:
		facing = input_vec.normalized()

	# The character (and its weapon) always faces the mouse cursor.
	var aim := _aim_dir()
	sprite.rotation = aim.angle()

	_attack_cd = max(0.0, _attack_cd - delta)
	_ability_cd = max(0.0, _ability_cd - delta)
	_attack_anim_timer = max(0.0, _attack_anim_timer - delta)
	ability_ready_changed.emit(1.0 - (_ability_cd / float(stats.ability_cooldown)))

	if Input.is_action_pressed("attack") and _attack_cd <= 0.0:
		_do_attack()
	if Input.is_action_just_pressed("ability") and _ability_cd <= 0.0:
		_do_ability()
	for i in range(4):
		if Input.is_action_just_pressed("use_item_%d" % (i + 1)):
			_use_inventory_slot(i)

	if _attack_anim_timer <= 0.0:
		var state := "walk" if input_vec.length() > 0.1 else "idle"
		if sprite.animation != state:
			sprite.play(state)


func _aim_dir() -> Vector2:
	var d := get_global_mouse_position() - global_position
	if d.length() < 1.0:
		return facing
	return d.normalized()


func _play_attack_anim() -> void:
	sprite.play("attack")
	_attack_anim_timer = ATTACK_ANIM_TIME


func _do_attack() -> void:
	_attack_cd = stats.attack_cooldown
	_play_attack_anim()
	var aim := _aim_dir()
	if stats.attack_type == "melee":
		for enemy in get_tree().get_nodes_in_group("enemy"):
			var to_enemy: Vector2 = enemy.global_position - global_position
			if to_enemy.length() <= stats.melee_range and to_enemy.normalized().dot(aim) > 0.3:
				enemy.take_damage(damage, global_position)
	else:
		var proj := Projectile.new()
		proj.direction = aim
		proj.speed = stats.projectile_speed
		proj.damage = damage
		proj.sprite_path = stats.projectile_sprite
		proj.is_enemy_projectile = false
		proj.global_position = global_position + aim * 14.0
		get_parent().add_child(proj)


func _do_ability() -> void:
	_ability_cd = stats.ability_cooldown
	_play_attack_anim()
	match GameManager.player_class_id:
		"priest":
			for target in get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("ally"):
				if target.global_position.distance_to(global_position) <= stats.ability_radius:
					if target.has_method("heal"):
						target.heal(stats.ability_heal)
		_:
			for enemy in get_tree().get_nodes_in_group("enemy"):
				if enemy.global_position.distance_to(global_position) <= stats.ability_radius:
					enemy.take_damage(stats.ability_damage, global_position)
					if enemy.has_method("apply_knockback"):
						var dir: Vector2 = (enemy.global_position - global_position).normalized()
						enemy.apply_knockback(dir, 160.0)


func _use_inventory_slot(slot_index: int) -> void:
	if slot_index >= GameManager.inventory.size():
		return
	var item_id := GameManager.use_item_slot(slot_index)
	if item_id == "":
		return
	var data := ItemData.get_item(item_id)
	if data.has("heal_percent"):
		heal(int(max_hp * float(data.heal_percent)))


func take_damage(amount: int, _from_pos: Vector2 = Vector2.ZERO) -> void:
	if not _alive:
		return
	hp = max(0, hp - amount)
	hp_changed.emit(hp, max_hp)
	_flash()
	if hp <= 0:
		die()


func heal(amount: int) -> void:
	if not _alive:
		return
	hp = min(max_hp, hp + amount)
	hp_changed.emit(hp, max_hp)


func _flash() -> void:
	sprite.modulate = Color(1, 0.4, 0.4)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(1, 1, 1), 0.15)


func die() -> void:
	if not _alive:
		return
	_alive = false
	set_physics_process(false)
	sprite.play("death")
	died.emit()
	await sprite.animation_finished
	GameManager.report_game_over()
