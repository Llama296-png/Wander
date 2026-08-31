extends Node
## Persistent meta-progression: XP per class, derived levels, and which
## classes are unlocked. Survives between play sessions via a small JSON
## file in the user's save directory. Autoloaded as "SaveManager".

signal progress_changed

const SAVE_PATH := "user://wander_save.json"
const XP_PER_LEVEL := 100
const MAX_LEVEL := 5
const UNLOCK_THRESHOLDS := {"warrior": 0, "mage": 60, "priest": 180}

var total_xp: int = 0
var class_xp: Dictionary = {"warrior": 0, "mage": 0, "priest": 0}


func _ready() -> void:
	load_data()


func is_unlocked(class_id: String) -> bool:
	return total_xp >= UNLOCK_THRESHOLDS.get(class_id, 0)


func unlock_xp_needed(class_id: String) -> int:
	return max(0, UNLOCK_THRESHOLDS.get(class_id, 0) - total_xp)


func get_xp(class_id: String) -> int:
	return int(class_xp.get(class_id, 0))


func get_level(class_id: String) -> int:
	return clampi(1 + int(get_xp(class_id) / float(XP_PER_LEVEL)), 1, MAX_LEVEL)


func xp_into_level(class_id: String) -> int:
	return get_xp(class_id) % XP_PER_LEVEL


func level_stat_mult(class_id: String) -> float:
	# +8% max_hp/damage per level above 1.
	return 1.0 + float(get_level(class_id) - 1) * 0.08


func add_run_xp(class_id: String, amount: int) -> void:
	if amount <= 0:
		return
	total_xp += amount
	class_xp[class_id] = get_xp(class_id) + amount
	save_data()
	progress_changed.emit()


func save_data() -> void:
	var data := {"total_xp": total_xp, "class_xp": class_xp}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	total_xp = int(parsed.get("total_xp", 0))
	var saved_xp = parsed.get("class_xp", {})
	if typeof(saved_xp) == TYPE_DICTIONARY:
		for class_id in saved_xp.keys():
			class_xp[class_id] = int(saved_xp[class_id])
