extends CanvasLayer
## In-game heads-up display: player HP/ability, floor/score, party status and
## the inventory bar. Rebuilt reactively from GameManager signals.

const ItemData = preload("res://scripts/data/ItemData.gd")
const ClassData = preload("res://scripts/data/ClassData.gd")
const PersonalityData = preload("res://scripts/data/PersonalityData.gd")

var player

var hp_bar: ProgressBar
var hp_label: Label
var ability_bar: ProgressBar
var ability_label: Label
var depth_label: Label
var score_label: Label
var party_box: HBoxContainer
var inventory_box: HBoxContainer


func _ready() -> void:
	layer = 5

	hp_bar = ProgressBar.new()
	hp_bar.position = Vector2(8, 8)
	hp_bar.size = Vector2(130, 12)
	hp_bar.show_percentage = false
	add_child(hp_bar)

	hp_label = Label.new()
	hp_label.position = Vector2(8, 8)
	hp_label.size = Vector2(130, 12)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 10)
	add_child(hp_label)

	ability_label = Label.new()
	ability_label.position = Vector2(8, 22)
	ability_label.size = Vector2(130, 12)
	ability_label.add_theme_font_size_override("font_size", 9)
	ability_label.text = "Ability"
	add_child(ability_label)

	ability_bar = ProgressBar.new()
	ability_bar.position = Vector2(8, 34)
	ability_bar.size = Vector2(90, 6)
	ability_bar.show_percentage = false
	ability_bar.max_value = 100
	add_child(ability_bar)

	depth_label = Label.new()
	depth_label.position = Vector2(370, 8)
	depth_label.size = Vector2(102, 14)
	depth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(depth_label)

	score_label = Label.new()
	score_label.position = Vector2(370, 22)
	score_label.size = Vector2(102, 14)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(score_label)

	party_box = HBoxContainer.new()
	party_box.position = Vector2(8, 46)
	party_box.add_theme_constant_override("separation", 3)
	add_child(party_box)

	inventory_box = HBoxContainer.new()
	inventory_box.position = Vector2(152, 234)
	inventory_box.add_theme_constant_override("separation", 4)
	add_child(inventory_box)

	GameManager.score_changed.connect(_on_score_changed)
	GameManager.depth_changed.connect(_on_depth_changed)
	GameManager.party_changed.connect(_rebuild_party)
	GameManager.inventory_changed.connect(_rebuild_inventory)

	_on_score_changed(GameManager.score)
	_on_depth_changed(GameManager.depth)
	_rebuild_party()
	_rebuild_inventory()


func set_player(p) -> void:
	player = p
	player.hp_changed.connect(_on_hp_changed)
	player.ability_ready_changed.connect(_on_ability_ready_changed)
	_on_hp_changed(player.hp, player.max_hp)


func _on_hp_changed(hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_label.text = "%d / %d" % [hp, max_hp]


func _on_ability_ready_changed(ratio: float) -> void:
	ability_bar.value = clampf(ratio, 0.0, 1.0) * 100.0
	ability_label.text = "Ability: READY" if ratio >= 1.0 else "Ability"


func _on_score_changed(score: int) -> void:
	score_label.text = "Gold: %d" % score


func _on_depth_changed(depth: int) -> void:
	depth_label.text = "Floor %d" % depth


func _rebuild_party() -> void:
	for c in party_box.get_children():
		c.queue_free()
	for entry in GameManager.party:
		var stats := ClassData.get_stats(entry.class_id)
		var personality := PersonalityData.get_personality(entry.get("personality_id", "stoic"))
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 1)

		var icon := TextureRect.new()
		icon.texture = load("res://assets/sprites/%s_idle_0.png" % stats.anim_prefix_ally)
		icon.custom_minimum_size = Vector2(20, 20)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.tooltip_text = "%s (%s)" % [stats.display_name, personality.display_name]
		col.add_child(icon)

		var tag := ColorRect.new()
		tag.color = personality.color
		tag.custom_minimum_size = Vector2(20, 2)
		col.add_child(tag)

		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(20, 5)
		bar.show_percentage = false
		bar.max_value = entry.max_hp
		bar.value = entry.hp
		col.add_child(bar)

		party_box.add_child(col)


func _rebuild_inventory() -> void:
	for c in inventory_box.get_children():
		c.queue_free()
	for i in range(GameManager.MAX_INVENTORY_SLOTS):
		var slot_panel := Panel.new()
		slot_panel.custom_minimum_size = Vector2(36, 36)

		if i < GameManager.inventory.size():
			var slot: Dictionary = GameManager.inventory[i]
			var data := ItemData.get_item(slot.id)
			var icon := TextureRect.new()
			icon.texture = load(data.sprite)
			icon.size = Vector2(28, 28)
			icon.position = Vector2(4, 2)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			slot_panel.add_child(icon)

			var count_label := Label.new()
			count_label.text = str(slot.count)
			count_label.position = Vector2(0, 20)
			count_label.size = Vector2(34, 14)
			count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			count_label.add_theme_font_size_override("font_size", 10)
			slot_panel.add_child(count_label)

		var key_label := Label.new()
		key_label.text = str(i + 1)
		key_label.position = Vector2(2, 0)
		key_label.size = Vector2(12, 12)
		key_label.add_theme_font_size_override("font_size", 9)
		key_label.modulate = Color(1, 1, 1, 0.6)
		slot_panel.add_child(key_label)

		inventory_box.add_child(slot_panel)
