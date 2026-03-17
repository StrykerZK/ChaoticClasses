extends Node

signal players_loaded

@export var player_scene: PackedScene

var game_node: Node
var game_manager: Node
var main_ui: Node

func _ready():
	game_node = get_parent()
	game_manager = $/root/Main/Game/GameManager
	main_ui = $/root/Main/Game/MainUI
	
	players_loaded.connect(Callable(game_node,"start_game"))
	players_loaded.connect(Callable(game_manager,"assign_players"))
	players_loaded.connect(Callable(main_ui,"assign_players"))
	
	create_players()

func create_players():
	var index = 1
	for i in StageManager.player_list:
		var current_player = player_scene.instantiate()
		current_player.name = str(StageManager.player_list[i].id)
		for spawn in get_tree().get_nodes_in_group("spawnpoints"):
			if spawn.name == str("Player"+str(index)+"Spawn"):
				current_player.position = spawn.global_position
		add_child(current_player, true)
		index += 1
	players_loaded.emit()
	game_node.start_game()
