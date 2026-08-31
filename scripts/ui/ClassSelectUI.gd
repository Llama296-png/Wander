extends CanvasLayer
## The title / class-select screen. Built entirely in code.

const ClassData = preload("res://scripts/data/ClassData.gd")

signal class_chosen(class_id: String)

const ORDER := ["warrior", "mage", "priest"]
const BLURBS := {
	"warrior": "Tough melee fighter.\nShield Bash knocks\nback nearby foes.",
	"mage": "Fragile ranged caster.\nArcane Nova deals big\nAoE damage.",
	"priest": "Sturdy ranged support.\nHeal Pulse restores\nyou and your allies.",
}


func _ready() -> void:
	layer = 10

	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.06, 0.09, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "WANDER"
	title.position = Vector2(0, 12)
	title.size = Vector2(480, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose your class"
	subtitle.position = Vector2(0, 44)
	subtitle.size = Vector2(480, 16)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)

	var xs := [10, 170, 330]
	for i in range(ORDER.size()):
		_build_panel(ORDER[i], xs[i])

	var hint := Label.new()
	hint.text = "Move: WASD  |  Attack: Click/J  |  Ability: Space/K  |  Items: 1-4"
	hint.position = Vector2(0, 250)
	hint.size = Vector2(480, 16)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	hint.modulate = Color(1, 1, 1, 0.7)
	add_child(hint)


func _build_panel(class_id: String, x: int) -> void:
	var stats := ClassData.get_stats(class_id)

	var panel := Panel.new()
	panel.position = Vector2(x, 68)
	panel.size = Vector2(140, 172)
	add_child(panel)

	var icon := TextureRect.new()
	icon.texture = load(stats.sprite_player)
	icon.size = Vector2(48, 48)
	icon.position = Vector2(46, 10)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.add_child(icon)

	var name_label := Label.new()
	name_label.text = stats.display_name
	name_label.position = Vector2(0, 62)
	name_label.size = Vector2(140, 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 15)
	panel.add_child(name_label)

	var stat_label := Label.new()
	stat_label.text = "HP %d    DMG %d" % [stats.max_hp, stats.damage]
	stat_label.position = Vector2(0, 84)
	stat_label.size = Vector2(140, 16)
	stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat_label.add_theme_font_size_override("font_size", 11)
	panel.add_child(stat_label)

	var blurb := Label.new()
	blurb.text = BLURBS.get(class_id, "")
	blurb.position = Vector2(8, 104)
	blurb.size = Vector2(124, 50)
	blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blurb.add_theme_font_size_override("font_size", 10)
	panel.add_child(blurb)

	var button := Button.new()
	button.text = "Choose"
	button.position = Vector2(20, 138)
	button.size = Vector2(100, 26)
	button.pressed.connect(func(): class_chosen.emit(class_id))
	panel.add_child(button)
