extends Area2D
## A rescued ally standing in a cleared room. Touching it (if there's room in
## the party) spawns a real Ally entity via `on_recruited`.

const ClassData = preload("res://scripts/data/ClassData.gd")
const AnimSetup = preload("res://scripts/entities/AnimSetup.gd")

var class_id: String = "warrior"
var on_recruited: Callable = Callable()

var _bob_time: float = 0.0
var _base_y: float = 0.0


func _ready() -> void:
	var stats := ClassData.ally_stats(class_id)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = AnimSetup.build(stats.anim_prefix)
	sprite.play("idle")
	sprite.scale = Vector2(1.3, 1.3)
	add_child(sprite)

	var glow := Sprite2D.new()
	glow.texture = load("res://assets/sprites/item_gold.png")
	glow.scale = Vector2(0.6, 0.6)
	glow.position = Vector2(0, -18)
	glow.modulate = Color(1, 1, 1, 0.8)
	add_child(glow)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	add_child(shape)

	collision_layer = 0
	set_collision_layer_value(7, true)
	set_collision_mask_value(2, true)
	monitoring = true
	monitorable = false

	_base_y = position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_bob_time += delta * 2.0
	position.y = _base_y + sin(_bob_time) * 3.0


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not GameManager.can_recruit():
		return
	if on_recruited.is_valid():
		# Deferred: we're inside the physics server's query flush right now,
		# and recruiting spawns a whole new physics body (the Ally) --
		# Godot refuses to set up collision state until the current physics
		# step finishes flushing.
		on_recruited.call_deferred(class_id)
	queue_free()
