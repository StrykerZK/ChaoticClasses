extends Node

@export var player_scene: PackedScene

func _ready():
	var index = 1
	for i in StageManager.player_list:
		var current_player = player_scene.instantiate()
		current_player.name = str(StageManager.player_list[i].id)
		for spawn in get_tree().get_nodes_in_group("spawnpoints"):
			if spawn.name == str("Player"+str(index)+"Spawn"):
				current_player.position = spawn.global_position
		$/root/Main/PlayerManager.add_child(current_player)
		index += 1
