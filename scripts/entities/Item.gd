extends Area2D
## A pickup that drops on the ground. Set `item_id` before `add_child()`.

const ItemData = preload("res://scripts/data/ItemData.gd")

var item_id: String = "gold"

var _bob_time: float = 0.0
var _base_y: float = 0.0


func _ready() -> void:
	var data := ItemData.get_item(item_id)
	var sprite := Sprite2D.new()
	sprite.texture = load(data.sprite)
	sprite.scale = Vector2(1.5, 1.5)
	sprite.name = "Sprite2D"
	add_child(sprite)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0
	shape.shape = circle
	add_child(shape)

	set_collision_layer_value(7, true)
	set_collision_layer_value(1, false)
	set_collision_mask_value(2, true)
	monitoring = true
	monitorable = false

	_base_y = position.y
	_bob_time = randf() * TAU
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_bob_time += delta * 3.0
	position.y = _base_y + sin(_bob_time) * 2.5


func _on_body_entered(body) -> void:
	if not body.is_in_group("player"):
		return
	var data := ItemData.get_item(item_id)
	if data.get("storable", false):
		GameManager.add_item(item_id, 1)
	elif data.has("score"):
		GameManager.add_score(int(data.score))
	elif data.has("damage_mult_bonus"):
		GameManager.bonus_damage_mult += float(data.damage_mult_bonus)
		if body.has_method("apply_stat_bonus"):
			body.apply_stat_bonus(0, data.damage_mult_bonus)
	elif data.has("max_hp_bonus"):
		GameManager.bonus_max_hp += int(data.max_hp_bonus)
		if body.has_method("apply_stat_bonus"):
			body.apply_stat_bonus(int(data.max_hp_bonus), 0.0)
	queue_free()
