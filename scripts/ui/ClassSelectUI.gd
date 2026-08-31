extends CanvasLayer
## The title / class-select screen. Built entirely in code. Lets the player
## pick a class (locked ones show what's needed to unlock them), how many
## allies to start with (0-10), and whether to play in pacifist mode.

const ClassData = preload("res://scripts/data/ClassData.gd")

signal class_chosen(class_id: String, party_size: int, pacifist: bool)

const ORDER := ["warrior", "mage", "priest"]
const BLURBS := {
	"warrior": "Melee. Shield Bash\nknocks back foes.",
	"mage": "Ranged. Arcane Nova\nis a big AoE nuke.",
	"priest": "Ranged. Heal Pulse\nheals you & allies.",
}

var party_size: int = 0
var pacifist: bool = false

var _party_label: Label
var _pacifist_button: Button


func _ready() -> void:
	layer = 10

	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.06, 0.09, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "WANDER"
	title.position = Vector2(0, 4)
	title.size = Vector2(480, 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose your class"
	subtitle.position = Vector2(0, 26)
	subtitle.size = Vector2(480, 14)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)

	var xs := [10, 170, 330]
	for i in range(ORDER.size()):
		_build_panel(ORDER[i], xs[i])

	_build_party_row()
	_build_pacifist_row()

	var hint := Label.new()
	hint.text = "Move: WASD | Attack: Click/J | Ability: Space/K | Items: 1-4"
	hint.position = Vector2(0, 258)
	hint.size = Vector2(480, 12)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 9)
	hint.modulate = Color(1, 1, 1, 0.7)
	add_child(hint)


func _build_panel(class_id: String, x: int) -> void:
	var stats := ClassData.get_stats(class_id)
	var unlocked := SaveManager.is_unlocked(class_id)

	var panel := Panel.new()
	panel.position = Vector2(x, 40)
	panel.size = Vector2(140, 168)
	add_child(panel)

	var icon := TextureRect.new()
	icon.texture = load("res://assets/sprites/%s_idle_0.png" % stats.anim_prefix_player)
	icon.size = Vector2(40, 40)
	icon.position = Vector2(50, 6)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not unlocked:
		icon.modulate = Color(0.5, 0.5, 0.5)
	panel.add_child(icon)

	var name_label := Label.new()
	name_label.text = stats.display_name
	name_label.position = Vector2(0, 48)
	name_label.size = Vector2(140, 16)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	panel.add_child(name_label)

	var stat_label := Label.new()
	stat_label.text = "HP %d    DMG %d" % [stats.max_hp, stats.damage]
	stat_label.position = Vector2(0, 64)
	stat_label.size = Vector2(140, 13)
	stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat_label.add_theme_font_size_override("font_size", 10)
	panel.add_child(stat_label)

	var level_label := Label.new()
	level_label.position = Vector2(0, 77)
	level_label.size = Vector2(140, 12)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 9)
	if unlocked:
		var level := SaveManager.get_level(class_id)
		level_label.text = "Lv %d  (%d/%d XP)" % [level, SaveManager.xp_into_level(class_id), SaveManager.XP_PER_LEVEL]
	else:
		level_label.text = "Locked: need %d XP" % SaveManager.unlock_xp_needed(class_id)
		level_label.modulate = Color(0.9, 0.6, 0.4)
	panel.add_child(level_label)

	var blurb := Label.new()
	blurb.text = BLURBS.get(class_id, "")
	blurb.position = Vector2(6, 91)
	blurb.size = Vector2(128, 46)
	blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blurb.add_theme_font_size_override("font_size", 9)
	panel.add_child(blurb)

	var button := Button.new()
	button.position = Vector2(20, 142)
	button.size = Vector2(100, 22)
	if unlocked:
		button.text = "Choose"
		button.pressed.connect(func(): class_chosen.emit(class_id, party_size, pacifist))
	else:
		button.text = "Locked"
		button.disabled = true
	panel.add_child(button)


func _build_party_row() -> void:
	var minus := Button.new()
	minus.text = "-"
	minus.position = Vector2(180, 212)
	minus.size = Vector2(24, 20)
	minus.pressed.connect(func(): _set_party_size(party_size - 1))
	add_child(minus)

	_party_label = Label.new()
	_party_label.position = Vector2(208, 212)
	_party_label.size = Vector2(64, 20)
	_party_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_party_label.text = "Allies: 0"
	add_child(_party_label)

	var plus := Button.new()
	plus.text = "+"
	plus.position = Vector2(276, 212)
	plus.size = Vector2(24, 20)
	plus.pressed.connect(func(): _set_party_size(party_size + 1))
	add_child(plus)


func _set_party_size(v: int) -> void:
	party_size = clampi(v, 0, GameManager.MAX_PARTY_SIZE)
	_party_label.text = "Allies: %d" % party_size


func _build_pacifist_row() -> void:
	_pacifist_button = Button.new()
	_pacifist_button.position = Vector2(180, 236)
	_pacifist_button.size = Vector2(120, 20)
	_pacifist_button.toggle_mode = true
	_pacifist_button.pressed.connect(_on_pacifist_pressed)
	add_child(_pacifist_button)
	_update_pacifist_label()


func _on_pacifist_pressed() -> void:
	pacifist = _pacifist_button.button_pressed
	_update_pacifist_label()


func _update_pacifist_label() -> void:
	_pacifist_button.text = "Pacifist: ON" if pacifist else "Pacifist: OFF"
