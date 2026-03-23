extends Node

signal players_loaded

@export var player_scene: PackedScene

var game_node: Node
var game_manager: Node
var main_ui: Node
var multiplayer_spawner: Node
var spawned_count: int = 0

func _ready():
	game_node = get_parent()
	game_manager = $/root/Main/Game/GameManager
	main_ui = $/root/Main/Game/MainUI
	multiplayer_spawner = $/root/Main/Game/PlayerManager/MultiplayerSpawner
	
	players_loaded.connect(Callable(game_node,"start_game"))
	players_loaded.connect(Callable(game_manager,"assign_players"))
	players_loaded.connect(Callable(main_ui,"assign_players"))
	
	multiplayer_spawner.spawn_function = _on_spawn_custom
	multiplayer_spawner.spawned.connect(_on_player_spawned)
	
	if multiplayer.is_server():
		create_players()

func create_players():
	if not multiplayer.is_server():
		return # ONLY the server spawns
	
	var index = 1
	for i in StageManager.player_list:
		var p_id = StageManager.player_list[i].id
		var spawn_pos = Vector2.ZERO
		
		for spawn in get_tree().get_nodes_in_group("spawnpoints"):
			if spawn.name == str("Player" + str(index) + "Spawn"):
				spawn_pos = spawn.global_position
		
		var new_player = multiplayer_spawner.spawn({"id": p_id, "pos": spawn_pos})
		index += 1
		
		_on_player_spawned(new_player)

func _on_spawn_custom(data):
	var p = player_scene.instantiate()
	p.name = str(data.id)
	p.global_position = data.pos
	return p

func _on_player_spawned(_node):
	spawned_count += 1
	if spawned_count >= StageManager.player_list.size():
		await get_tree().process_frame
		players_loaded.emit()
		spawned_count = 0
