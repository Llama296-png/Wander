extends Node
## Room theme definitions: floor/wall textures and decorative props, picked
## once per room at generation time (rooms persist, so the theme sticks).

const DIR := "res://assets/sprites/"

const THEMES := {
	"bathroom": {
		"display_name": "Bathroom",
		"floor": DIR + "theme_bathroom_floor.png",
		"wall": DIR + "theme_bathroom_wall.png",
		"props": [DIR + "theme_bathroom_prop_bathtub.png", DIR + "theme_bathroom_prop_sink.png"],
	},
	"living_room": {
		"display_name": "Living Room",
		"floor": DIR + "theme_living_room_floor.png",
		"wall": DIR + "theme_living_room_wall.png",
		"props": [DIR + "theme_living_room_prop_couch.png", DIR + "theme_living_room_prop_tv.png"],
	},
	"garage": {
		"display_name": "Garage",
		"floor": DIR + "theme_garage_floor.png",
		"wall": DIR + "theme_garage_wall.png",
		"props": [DIR + "theme_garage_prop_car.png", DIR + "theme_garage_prop_toolbox.png"],
	},
	"bedroom": {
		"display_name": "Bedroom",
		"floor": DIR + "theme_bedroom_floor.png",
		"wall": DIR + "theme_bedroom_wall.png",
		"props": [DIR + "theme_bedroom_prop_bed.png", DIR + "theme_bedroom_prop_dresser.png"],
	},
	"master_bedroom": {
		"display_name": "Master Bedroom",
		"floor": DIR + "theme_master_bedroom_floor.png",
		"wall": DIR + "theme_master_bedroom_wall.png",
		"props": [DIR + "theme_master_bedroom_prop_big_bed.png", DIR + "theme_master_bedroom_prop_vanity.png"],
	},
	"kitchen": {
		"display_name": "Kitchen",
		"floor": DIR + "theme_kitchen_floor.png",
		"wall": DIR + "theme_kitchen_wall.png",
		"props": [DIR + "theme_kitchen_prop_stove.png", DIR + "theme_kitchen_prop_fridge.png"],
	},
}

const IDS := ["bathroom", "living_room", "garage", "bedroom", "master_bedroom", "kitchen"]


static func get_theme(id: String) -> Dictionary:
	return THEMES.get(id, THEMES.bathroom)


static func random_id(rng: RandomNumberGenerator) -> String:
	return IDS[rng.randi_range(0, IDS.size() - 1)]
