extends Node

var maps_directory: String = "res://scenes/environment/maps/"

# Summons
var summon_registry: Dictionary = {
	"skull_archer": preload("res://scenes/summons/skeleton_archer.tscn"),
	"skull_soldier": preload("res://scenes/summons/skeleton_soldier.tscn")
}

func _ready() -> void:
	load_map(MapManager.get_current_map())
	
	%SummonSpawner.spawn_function = _on_summon_custom

func load_map(map: String) -> void:
	var scene_path: String = MapManager.get_map_scene_path()
	if FileAccess.file_exists(scene_path):
		var map_scene = load(scene_path)
		var map_instance = map_scene.instantiate()
		add_child(map_instance)
		move_child(map_instance, 0)
	else:
		print("ERROR: MAP NOT FOUND")

func get_player_spawner() -> MultiplayerSpawner:
	return %PlayerSpawner

func spawn_summon(data: Dictionary) -> void:
	if !multiplayer.is_server(): return
	
	%SummonSpawner.spawn(data)

func _on_summon_custom(data: Dictionary):
	var summon = summon_registry.get(data.type).instantiate()
	summon.name = str(data.name)
	summon.player_id = data.player_id
	summon.global_position = data.pos
	return summon

func spawn_misc(misc: Node) -> void:
	$EntityContainer/Misc.add_child(misc)
