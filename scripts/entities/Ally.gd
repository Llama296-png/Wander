extends CharacterBody2D
## An AI-controlled party member that follows the player and fights nearby
## enemies. Persists across room transitions (created once on recruit).
## Set `class_id`, `ally_id` and `formation_offset` before `add_child()`.

const ClassData = preload("res://scripts/data/ClassData.gd")
const PersonalityData = preload("res://scripts/data/PersonalityData.gd")
const Projectile = preload("res://scripts/entities/Projectile.gd")
const AnimSetup = preload("res://scripts/entities/AnimSetup.gd")

const BASE_AGGRO_RANGE := 220.0
const BASE_FOLLOW_STOP_DIST := 18.0
const BASE_HEAL_THRESHOLD := 0.6
const ATTACK_ANIM_TIME := 0.3

var class_id: String = "warrior"
var ally_id: int = -1
var formation_offset: Vector2 = Vector2(-30, 24)

var stats: Dictionary
var personality: Dictionary
var max_hp: int
var hp: int
var damage: int
var speed: float
var melee_range: float
var attack_cooldown: float
var aggro_range: float
var follow_stop_dist: float
var heal_threshold: float

var _attack_cd: float = 0.0
var _ability_cd: float = 0.0
var _attack_anim_timer: float = 0.0
var _alive: bool = true
var sprite: AnimatedSprite2D
var weapon: Sprite2D
var _charge_glow: Sprite2D
var _player: Node2D
## Body rotation -- follows movement direction only.
var _body_facing: Vector2 = Vector2.RIGHT
## Weapon rotation -- follows the current attack target, or the body when
## there isn't one.
var _weapon_facing: Vector2 = Vector2.RIGHT
var _wander_dir: Vector2 = Vector2.ZERO
var _wander_time: float = 0.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("ally")
	stats = ClassData.ally_stats(class_id)
	personality = PersonalityData.get_personality(_lookup_personality_id())

	var s := AnimatedSprite2D.new()
	s.sprite_frames = AnimSetup.build(stats.anim_prefix)
	s.play("idle")
	s.scale = Vector2(1.3, 1.3)
	add_child(s)
	sprite = s

	var w := Sprite2D.new()
	w.texture = load("res://assets/sprites/weapon_%s.png" % stats.anim_prefix)
	w.scale = Vector2(1.3, 1.3)
	add_child(w)
	weapon = w

	if stats.attack_type == "ranged":
		var glow := Sprite2D.new()
		glow.texture = load(stats.projectile_sprite)
		glow.scale = Vector2.ZERO
		glow.position = Vector2(10, 0)
		weapon.add_child(glow)
		_charge_glow = glow

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
	attack_cooldown = stats.attack_cooldown * personality.attack_cd_mult
	aggro_range = BASE_AGGRO_RANGE * personality.aggro_mult
	follow_stop_dist = BASE_FOLLOW_STOP_DIST * personality.follow_mult
	heal_threshold = BASE_HEAL_THRESHOLD * personality.heal_threshold_mult

	_player = get_tree().get_first_node_in_group("player") as Node2D
	GameManager.update_ally_hp(ally_id, hp)


func _lookup_personality_id() -> String:
	for entry in GameManager.party:
		if entry.id == ally_id:
			return entry.get("personality_id", "stoic")
	return "stoic"


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_attack_cd = max(0.0, _attack_cd - delta)
	_ability_cd = max(0.0, _ability_cd - delta)
	_attack_anim_timer = max(0.0, _attack_anim_timer - delta)

	if class_id == "priest" and _ability_cd <= 0.0 and _try_heal():
		return

	var aiming_at_target := false
	if GameManager.pacifist_mode:
		# Pacifist allies never fight -- they just wander the room instead
		# of hunting enemies or sticking close to the player.
		_wander(delta)
	else:
		var target = _find_nearest_enemy()
		if target:
			var to_target: Vector2 = target.global_position - global_position
			var dist := to_target.length()
			var atk_range: float = melee_range if stats.attack_type == "melee" else stats.get("ability_radius", 160.0)
			if dist > atk_range * 0.85:
				velocity = to_target.normalized() * speed
			else:
				velocity = Vector2.ZERO
				_weapon_facing = to_target.normalized()
				aiming_at_target = true
				if _attack_cd <= 0.0:
					_attack(target)
		else:
			_follow()

	if velocity.length() > 1.0:
		_body_facing = velocity.normalized()
	if not aiming_at_target:
		_weapon_facing = _body_facing

	if _attack_anim_timer <= 0.0:
		_apply_facing()
		var state := "walk" if velocity.length() > 1.0 else "idle"
		if sprite.animation != state:
			sprite.play(state)
	move_and_slide()


func _apply_facing() -> void:
	# Body never rotates -- it stays upright and only mirrors left/right.
	# Only the weapon rotates freely to face its target.
	if absf(_body_facing.x) > 0.01:
		sprite.flip_h = _body_facing.x < 0
	weapon.rotation = _weapon_facing.angle()


func _wander(delta: float) -> void:
	_wander_time -= delta
	if _wander_time <= 0.0:
		_wander_time = randf_range(0.8, 2.2)
		_wander_dir = Vector2.RIGHT.rotated(randf() * TAU) * (0.0 if randf() < 0.3 else 1.0)
	velocity = _wander_dir * speed * 0.5


func _follow() -> void:
	if not is_instance_valid(_player):
		velocity = Vector2.ZERO
		return
	var goal: Vector2 = _player.global_position + formation_offset
	var to_goal: Vector2 = goal - global_position
	if to_goal.length() > follow_stop_dist:
		velocity = to_goal.normalized() * speed
	else:
		velocity = Vector2.ZERO


func _find_nearest_enemy():
	var best = null
	var best_dist := aggro_range
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var d: float = global_position.distance_to(enemy.global_position)
		if d < best_dist:
			best_dist = d
			best = enemy
	return best


func _attack(target) -> void:
	_attack_cd = attack_cooldown
	sprite.play("attack")
	_apply_facing()
	_attack_anim_timer = ATTACK_ANIM_TIME
	_play_weapon_flourish()
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
	var lowest_ratio := heal_threshold
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
		sprite.play("attack")
		_weapon_facing = (lowest.global_position - global_position).normalized() if lowest.global_position != global_position else _body_facing
		weapon.rotation = _weapon_facing.angle()
		_attack_anim_timer = ATTACK_ANIM_TIME
		_play_weapon_flourish()
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


func _play_weapon_flourish() -> void:
	var base_scale := Vector2(1.3, 1.3)
	weapon.scale = base_scale
	var tw := create_tween()
	tw.tween_property(weapon, "scale", base_scale * 1.25, ATTACK_ANIM_TIME * 0.35)
	tw.tween_property(weapon, "scale", base_scale, ATTACK_ANIM_TIME * 0.65)

	if _charge_glow:
		_charge_glow.scale = Vector2.ZERO
		var gtw := create_tween()
		gtw.tween_property(_charge_glow, "scale", Vector2.ONE, ATTACK_ANIM_TIME * 0.7)
		gtw.tween_property(_charge_glow, "scale", Vector2.ZERO, ATTACK_ANIM_TIME * 0.3)


func die() -> void:
	if not _alive:
		return
	_alive = false
	set_physics_process(false)
	remove_from_group("ally")
	weapon.visible = false
	sprite.play("death")
	# Fixed real-time delay rather than awaiting the animation -- see the
	# matching comment in Enemy.gd::die().
	await get_tree().create_timer(0.4).timeout
	GameManager.remove_ally(ally_id)
	queue_free()
