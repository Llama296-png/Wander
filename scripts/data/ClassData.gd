extends Node
## Static lookup table describing each playable/ally class's stats and abilities.
## Not an autoload -- accessed as a class via `ClassData.CLASSES[...]` after
## `const ClassData = preload("res://scripts/data/ClassData.gd")`.

const CLASSES := {
	"warrior": {
		"display_name": "Warrior",
		"max_hp": 140,
		"speed": 92.0,
		"damage": 16,
		"attack_type": "melee",
		"melee_range": 22.0,
		"attack_cooldown": 0.45,
		"ability_name": "Shield Bash",
		"ability_cooldown": 4.0,
		"ability_radius": 46.0,
		"ability_damage": 24,
		"sprite_player": "res://assets/sprites/player_warrior.png",
		"sprite_ally": "res://assets/sprites/ally_warrior.png",
		"color": Color(0.55, 0.62, 0.95),
	},
	"mage": {
		"display_name": "Mage",
		"max_hp": 85,
		"speed": 96.0,
		"damage": 12,
		"attack_type": "ranged",
		"projectile_sprite": "res://assets/sprites/proj_fireball.png",
		"projectile_speed": 220.0,
		"attack_cooldown": 0.55,
		"ability_name": "Arcane Nova",
		"ability_cooldown": 6.0,
		"ability_radius": 70.0,
		"ability_damage": 30,
		"sprite_player": "res://assets/sprites/player_mage.png",
		"sprite_ally": "res://assets/sprites/ally_mage.png",
		"color": Color(0.75, 0.4, 0.95),
	},
	"priest": {
		"display_name": "Priest",
		"max_hp": 105,
		"speed": 94.0,
		"damage": 9,
		"attack_type": "ranged",
		"projectile_sprite": "res://assets/sprites/proj_holybolt.png",
		"projectile_speed": 210.0,
		"attack_cooldown": 0.5,
		"ability_name": "Heal Pulse",
		"ability_cooldown": 8.0,
		"ability_radius": 90.0,
		"ability_heal": 35,
		"sprite_player": "res://assets/sprites/player_priest.png",
		"sprite_ally": "res://assets/sprites/ally_priest.png",
		"color": Color(0.95, 0.85, 0.4),
	},
}


static func get_stats(class_id: String) -> Dictionary:
	return CLASSES.get(class_id, CLASSES["warrior"])


static func ally_stats(class_id: String) -> Dictionary:
	# Allies are a slightly weaker copy of the player-facing stats so a full
	# party doesn't trivialize fights.
	var base: Dictionary = get_stats(class_id).duplicate(true)
	base.max_hp = int(base.max_hp * 0.7)
	base.damage = int(base.damage * 0.7)
	return base
