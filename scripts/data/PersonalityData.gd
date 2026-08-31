extends Node
## Ally personalities: flavor + numeric multipliers applied to the base
## Ally AI tuning (see Ally.gd), so two allies of the same class still feel
## different to have around.

const PERSONALITIES := {
	"aggressive": {
		"display_name": "Aggressive",
		"color": Color(0.9, 0.35, 0.3),
		"aggro_mult": 1.4,
		"attack_cd_mult": 0.8,
		"heal_threshold_mult": 0.65,
		"follow_mult": 1.3,
	},
	"cautious": {
		"display_name": "Cautious",
		"color": Color(0.4, 0.7, 0.95),
		"aggro_mult": 0.7,
		"attack_cd_mult": 1.15,
		"heal_threshold_mult": 1.35,
		"follow_mult": 0.75,
	},
	"loyal": {
		"display_name": "Loyal",
		"color": Color(0.9, 0.8, 0.35),
		"aggro_mult": 0.9,
		"attack_cd_mult": 1.0,
		"heal_threshold_mult": 1.0,
		"follow_mult": 0.55,
	},
	"chaotic": {
		"display_name": "Chaotic",
		"color": Color(0.8, 0.4, 0.9),
		"aggro_mult": 1.6,
		"attack_cd_mult": 0.9,
		"heal_threshold_mult": 0.55,
		"follow_mult": 1.6,
	},
	"stoic": {
		"display_name": "Stoic",
		"color": Color(0.65, 0.65, 0.7),
		"aggro_mult": 1.0,
		"attack_cd_mult": 1.0,
		"heal_threshold_mult": 1.0,
		"follow_mult": 1.0,
	},
}

const IDS := ["aggressive", "cautious", "loyal", "chaotic", "stoic"]


static func get_personality(id: String) -> Dictionary:
	return PERSONALITIES.get(id, PERSONALITIES.stoic)


static func random_id(rng: RandomNumberGenerator) -> String:
	return IDS[rng.randi_range(0, IDS.size() - 1)]
