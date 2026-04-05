extends Node

var maps_directory: String = "res://scenes/environment/maps/"

func _ready() -> void:
	load_map(MapManager.get_current_map())

func load_map(map: String):
	var scene_path = MapManager.get_map_scene_path()
	if FileAccess.file_exists(scene_path):
		var map_scene = load(scene_path)
		var map_instance = map_scene.instantiate()
		add_child(map_instance)
		move_child(map_instance, 0)
	else:
		print("ERROR: MAP NOT FOUND")
