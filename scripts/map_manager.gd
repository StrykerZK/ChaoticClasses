extends Node

var map_data = {
	"Test_S1": {
		"path": "res://scenes/environment/maps/test_s1.tscn",
		"player_count": 4,
		"music": "res://sounds/music/battle/forest.mp3",
		"map_limit": Vector2(1088, 1088)
	},
	"Forest_S1": {
		"path": "res://scenes/environment/maps/forest_small.tscn",
		"player_count": 2,
		"music": "res://sounds/music/battle/forest.mp3",
		"map_limit": Vector2(0, 0)
	},
	"Forest_L1": {
		"path": "res://scenes/environment/maps/forest_big.tscn",
		"player_count": 4,
		"music": "res://sounds/music/battle/forest.mp3",
		"map_limit": Vector2(0, 0)
	},
	"LavaBig": {
		"path": "res://scenes/environment/maps/lava_big.tscn",
		"player_count": 4,
		"music": "res://sounds/music/battle/lava.mp3",
		"map_limit": Vector2(0, 0)
	}
}

var current_map: String = "Test_S1"

func set_current_map(map: String):
	current_map = map

func get_current_map() -> String:
	return current_map

func get_map_scene_path() -> String:
	return map_data[current_map].path

func get_map_limits() -> Vector2:
	return map_data[current_map].map_limit
