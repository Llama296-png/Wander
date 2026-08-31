extends Node
## Builds a Godot SpriteFrames resource from per-frame animation PNGs that
## follow the naming convention "res://assets/sprites/<prefix>_<state>_<i>.png",
## as produced by tools/gen_art.py. Shared by Player/Ally/Enemy so the four
## states (idle/walk/attack/death) are wired up identically everywhere.

const STATES := {
	"idle": {"count": 2, "fps": 4.0, "loop": true},
	"walk": {"count": 4, "fps": 8.0, "loop": true},
	"attack": {"count": 3, "fps": 14.0, "loop": false},
	"death": {"count": 4, "fps": 7.0, "loop": false},
}


static func build(prefix: String, overrides: Dictionary = {}) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for state_name in STATES.keys():
		var cfg: Dictionary = STATES[state_name].duplicate()
		cfg.merge(overrides.get(state_name, {}), true)
		frames.add_animation(state_name)
		frames.set_animation_speed(state_name, cfg.fps)
		frames.set_animation_loop(state_name, cfg.loop)
		for i in range(int(cfg.count)):
			var path := "res://assets/sprites/%s_%s_%d.png" % [prefix, state_name, i]
			frames.add_frame(state_name, load(path))
	return frames
