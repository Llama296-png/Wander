extends Area2D
## A simple straight-line projectile. Configure the exported fields right
## after `Projectile.new()` and before `add_child()`, then it wires itself
## up in `_ready()`.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 200.0
var damage: int = 10
var sprite_path: String = "res://assets/sprites/proj_fireball.png"
var lifetime: float = 2.0
var is_enemy_projectile: bool = false
var on_hit_extra: Callable = Callable()

var _age: float = 0.0


func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(sprite_path)
	sprite.scale = Vector2(1.5, 1.5)
	add_child(sprite)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	add_child(shape)

	monitoring = true
	monitorable = false
	collision_layer = 0
	if is_enemy_projectile:
		set_collision_layer_value(6, true)
		set_collision_mask_value(2, true)
		set_collision_mask_value(3, true)
	else:
		set_collision_layer_value(5, true)
		set_collision_mask_value(4, true)

	rotation = direction.angle()
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_age += delta
	if _age >= lifetime:
		queue_free()


func _on_body_entered(body) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)
	if on_hit_extra.is_valid():
		on_hit_extra.call(body)
	queue_free()
