extends Node
## Static lookup table + drop table for item pickups.

const ITEMS := {
	"potion": {
		"display_name": "Potion",
		"sprite": "res://assets/sprites/item_potion.png",
		"storable": true,
		"heal_percent": 0.4,
	},
	"mega_potion": {
		"display_name": "Mega Potion",
		"sprite": "res://assets/sprites/item_mega_potion.png",
		"storable": true,
		"heal_percent": 1.0,
	},
	"gold": {
		"display_name": "Gold",
		"sprite": "res://assets/sprites/item_gold.png",
		"storable": false,
		"score": 10,
	},
	"power_gem": {
		"display_name": "Power Gem",
		"sprite": "res://assets/sprites/item_power_gem.png",
		"storable": false,
		"damage_mult_bonus": 0.1,
	},
	"vitality_gem": {
		"display_name": "Vitality Gem",
		"sprite": "res://assets/sprites/item_vitality_gem.png",
		"storable": false,
		"max_hp_bonus": 15,
	},
}

## Weighted drop table: [item_id, weight]
const DROP_TABLE := [
	["gold", 40],
	["potion", 28],
	["mega_potion", 8],
	["power_gem", 12],
	["vitality_gem", 12],
]


static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})


static func roll_drop(rng: RandomNumberGenerator) -> String:
	var total := 0
	for entry in DROP_TABLE:
		total += entry[1]
	var roll := rng.randi_range(0, total - 1)
	var acc := 0
	for entry in DROP_TABLE:
		acc += entry[1]
		if roll < acc:
			return entry[0]
	return DROP_TABLE[0][0]
