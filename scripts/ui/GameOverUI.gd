extends CanvasLayer
## Death screen with run stats and a restart button.

signal restart_requested

var _floor_label: Label
var _score_label: Label


func _ready() -> void:
	layer = 20

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.02, 0.03, 0.88)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "You Died"
	title.position = Vector2(0, 80)
	title.size = Vector2(480, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	add_child(title)

	_floor_label = Label.new()
	_floor_label.position = Vector2(0, 120)
	_floor_label.size = Vector2(480, 18)
	_floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_floor_label)

	_score_label = Label.new()
	_score_label.position = Vector2(0, 138)
	_score_label.size = Vector2(480, 18)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_score_label)

	var button := Button.new()
	button.text = "Try Again"
	button.position = Vector2(190, 170)
	button.size = Vector2(100, 30)
	button.pressed.connect(func(): restart_requested.emit())
	add_child(button)


func show_result(depth_reached: int, score: int) -> void:
	_floor_label.text = "Reached Floor %d" % depth_reached
	_score_label.text = "Gold collected: %d" % score
