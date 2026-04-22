extends Node

var maps_directory: String = "res://scenes/environment/maps/"

func _ready() -> void:
	load_map(MapManager.get_current_map())
	
	%SummonSpawner.spawn_function = _on_summon_custom

func load_map(map: String):
	var scene_path = MapManager.get_map_scene_path()
	if FileAccess.file_exists(scene_path):
		var map_scene = load(scene_path)
		var map_instance = map_scene.instantiate()
		add_child(map_instance)
		move_child(map_instance, 0)
	else:
		print("ERROR: MAP NOT FOUND")

func get_player_spawner() -> MultiplayerSpawner:
	return $EntityContainer/Players/MultiplayerSpawner

func spawn_summon(summon: Node):
	if !multiplayer.is_server(): return
	
	%SummonSpawner.spawn()

func _on_summon_custom(data: Dictionary):
	var summon = preload(data.path).instantiate()
	p.name = str(data.id)
	p.global_position = data.pos
	return p

func spawn_misc(misc: Node):
	$EntityContainer/Misc.add_child(misc)
