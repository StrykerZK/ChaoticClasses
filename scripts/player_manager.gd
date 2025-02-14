extends Node

@export var player_scene: PackedScene

func _ready():
	var index = 1
	for i in StageManager.player_list:
		var current_player = player_scene.instantiate()
		current_player.name = str(StageManager.player_list[i].id)
		add_child(current_player)
		for spawn in get_tree().get_nodes_in_group("spawnpoints"):
			if spawn.name == str("Player"+str(index)+"Spawn"):
				current_player.global_position = spawn.global_position
		index += 1
