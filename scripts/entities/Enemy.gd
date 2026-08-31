extends CharacterBody2D
## A hostile creature. Set `enemy_type` and `difficulty_mult` before
## `add_child()`. `on_death` and `spawn_item` are Callables wired by whoever
## spawns the enemy (Room) so it can report kills / drop loot without
## knowing about Room directly.

const Projectile = preload("res://scripts/entities/Projectile.gd")

const TYPES := {
	"slime": {
		"sprite": "res://assets/sprites/enemy_slime.png",
		"hp": 26, "damage": 8, "speed": 46.0,
		"aggro_range": 130.0, "attack_range": 16.0, "attack_cooldown": 1.0,
		"attack_type": "melee", "score": 5, "scale": 1.8, "erratic": false,
	},
	"bat": {
		"sprite": "res://assets/sprites/enemy_bat.png",
		"hp": 16, "damage": 6, "speed": 92.0,
		"aggro_range": 150.0, "attack_range": 14.0, "attack_cooldown": 0.8,
		"attack_type": "melee", "score": 7, "scale": 1.7, "erratic": true,
	},
	"skeleton": {
		"sprite": "res://assets/sprites/enemy_skeleton.png",
		"hp": 30, "damage": 9, "speed": 52.0,
		"aggro_range": 190.0, "attack_range": 150.0, "attack_cooldown": 1.4,
		"attack_type": "ranged", "score": 10, "scale": 1.9, "erratic": false,
	},
	"brute": {
		"hp": 70, "damage": 16, "speed": 40.0,
		"sprite": "res://assets/sprites/enemy_brute.png",
		"aggro_range": 140.0, "attack_range": 20.0, "attack_cooldown": 1.1,
		"attack_type": "melee", "score": 18, "scale": 2.2, "erratic": false,
	},
}

var enemy_type: String = "slime"
var difficulty_mult: float = 1.0
var on_death: Callable = Callable()
var spawn_item: Callable = Callable()

var max_hp: int
var hp: int
var damage: int
var speed: float
var cfg: Dictionary

var _attack_cd: float = 0.0
var _wander_dir: Vector2 = Vector2.ZERO
var _wander_time: float = 0.0
var _knockback: Vector2 = Vector2.ZERO
var _alive: bool = true
var _target
var sprite: Sprite2D


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("enemy")
	cfg = TYPES.get(enemy_type, TYPES.slime)

	var s := Sprite2D.new()
	s.texture = load(cfg.sprite)
	s.scale = Vector2(cfg.scale, cfg.scale)
	add_child(s)
	sprite = s

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0 * (cfg.scale / 1.8)
	shape.shape = circle
	add_child(shape)

	collision_layer = 0
	set_collision_layer_value(4, true)
	set_collision_mask_value(1, true)

	max_hp = int(cfg.hp * difficulty_mult)
	hp = max_hp
	damage = int(cfg.damage * sqrt(difficulty_mult))
	speed = cfg.speed

	_target = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_attack_cd = max(0.0, _attack_cd - delta)

	if _knockback.length() > 4.0:
		velocity = _knockback
		_knockback = _knockback.lerp(Vector2.ZERO, 10.0 * delta)
		move_and_slide()
		return

	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player")

	if is_instance_valid(_target):
		var to_target: Vector2 = _target.global_position - global_position
		var dist := to_target.length()
		if dist <= cfg.aggro_range:
			if dist > cfg.attack_range * 0.8:
				var dir := to_target.normalized()
				if cfg.erratic:
					dir = dir.rotated(sin(Time.get_ticks_msec() * 0.01 + get_instance_id()) * 0.6)
				velocity = dir * speed
			else:
				velocity = Vector2.ZERO
			if dist <= cfg.attack_range and _attack_cd <= 0.0:
				_attack()
		else:
			_wander(delta)
	else:
		_wander(delta)

	if velocity.length() > 1.0:
		sprite.flip_h = velocity.x < 0
	move_and_slide()


func _wander(delta: float) -> void:
	_wander_time -= delta
	if _wander_time <= 0.0:
		_wander_time = randf_range(0.6, 1.8)
		_wander_dir = Vector2.RIGHT.rotated(randf() * TAU) * (0.0 if randf() < 0.4 else 1.0)
	velocity = _wander_dir * speed * 0.4


func _attack() -> void:
	_attack_cd = cfg.attack_cooldown
	if cfg.attack_type == "melee":
		if is_instance_valid(_target) and global_position.distance_to(_target.global_position) <= cfg.attack_range + 6.0:
			_target.take_damage(damage, global_position)
	else:
		var proj := Projectile.new()
		var dir: Vector2 = (_target.global_position - global_position).normalized()
		proj.direction = dir
		proj.speed = 150.0
		proj.damage = damage
		proj.sprite_path = "res://assets/sprites/proj_arrow.png"
		proj.is_enemy_projectile = true
		proj.global_position = global_position + dir * 12.0
		get_parent().add_child(proj)


func apply_knockback(dir: Vector2, force: float) -> void:
	_knockback = dir * force


func take_damage(amount: int, _from_pos: Vector2 = Vector2.ZERO) -> void:
	if not _alive:
		return
	hp = max(0, hp - amount)
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
	GameManager.add_score(cfg.score)
	if spawn_item.is_valid():
		spawn_item.call(global_position)
	if on_death.is_valid():
		on_death.call()
	queue_free()
