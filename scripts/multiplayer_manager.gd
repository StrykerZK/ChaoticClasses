extends Node

signal players_loaded

@export var player_scene: PackedScene

var transform_time: float = 2

var is_paused: bool = false
var pause_id: int

# Player Management
var player_1: CharacterBody2D
var player_2: CharacterBody2D
var player_3: CharacterBody2D
var player_4: CharacterBody2D
var player_count: int = 0
var players_alive: int = 0

# Player Spawning
var multiplayer_spawner: MultiplayerSpawner
var spawned_count: int = 0

var main_ui: CanvasLayer
var game_node: Node
var world_node: Node2D

func _ready():
	game_node = get_parent()
	main_ui = $"../MainUI"
	world_node = $"../World"
	multiplayer_spawner = world_node.get_player_spawner()
	player_count = StageManager.player_count
	
	players_loaded.connect(Callable(game_node,"start_game"))
	players_loaded.connect(Callable(self,"assign_players"))
	players_loaded.connect(Callable(main_ui,"assign_players"))
	
	multiplayer_spawner.spawn_function = _on_spawn_custom
	multiplayer_spawner.spawned.connect(_on_player_spawned)
	
	
func _input(event: InputEvent) -> void:
	if StageManager.game_state == StageManager.GameState.IN_GAME:
		if event.is_action_pressed("back"):
			toggle_pause.rpc(multiplayer.get_unique_id())

func _on_players_connected():
	players_alive += 1
	if players_alive == player_count:
		assign_players.rpc()
		main_ui.assign_players.rpc()

@rpc("any_peer","call_local")
func assign_players():
	for player in get_tree().get_nodes_in_group("players"):
		for i in StageManager.player_list:
			if player.name.to_int() != i: continue
			match StageManager.player_list[i].number:
				1: player_1 = player
				2: player_2 = player
				3: player_3 = player
				4: player_4 = player

@rpc("any_peer")
func class_change():	
	StageManager.update_game_state.rpc(StageManager.GameState.TRANSFORMING)
	
	# Randomize and get two new classes
	var class_title_1 = ClassManager.get_random_class(player_1.player_id)
	var class_title_2 = ClassManager.get_random_class(player_2.player_id)
	
	while class_title_1 == class_title_2:
		class_title_2 = ClassManager.get_random_class(player_2.player_id)
	
	
	# Update StageManager's player_list
	update_player_class.rpc(player_1.player_id, class_title_1)
	update_player_class.rpc(player_2.player_id, class_title_2)
	
	# Run class_change() method in players
	player_1.class_change.rpc(class_title_1)
	player_2.class_change.rpc(class_title_2)
	
	# For 3 players
	if player_count >= 3:
		var class_title_3 = ClassManager.get_random_class(player_3.player_id)
		while class_title_3 == class_title_1 and class_title_3 == class_title_2:
			class_title_3 = ClassManager.get_random_class(player_3.player_id)
		update_player_class.rpc(player_3.player_id, class_title_3)
		player_3.class_change.rpc(class_title_3)
	
	# For 4 players
	if player_count >= 4:
		var class_title_4 = ClassManager.get_random_class(player_4.player_id)
		while class_title_4 == class_title_1 and class_title_4 == class_title_2:
			class_title_4 = ClassManager.get_random_class(player_4.player_id)
		update_player_class.rpc(player_4.player_id, class_title_4)
		player_4.class_change.rpc(class_title_4)
	
	# Update player info
	if player_count == 2:
		await player_2.child_entered_tree
	elif player_count == 3:
		await player_3.child_entered_tree
	elif player_count == 4:
		await player_4.child_entered_tree
	else:
		await player_1.child_entered_tree
	main_ui.class_change.rpc()

@rpc("any_peer","call_local")
func toggle_pause(id: int): # id == 0 means non-player pausing
	
	if id != 0: # Checking if a player requested pause
		if !is_paused: # First time pausing, store who did it
			pause_id = id
		else:
			if id != pause_id: # If not the player who paused previously, cancle pause req
				return
	
	is_paused = !is_paused
	get_tree().paused = !get_tree().paused
	if is_instance_valid(player_1):
		player_1.toggle_pause()
	if is_instance_valid(player_2):
		player_2.toggle_pause()
	if is_instance_valid(player_3):
		player_3.toggle_pause()
	if is_instance_valid(player_4):
		player_4.toggle_pause()
	$SwapTimer.paused = !$SwapTimer.paused
	main_ui.toggle_pause()

@rpc("any_peer", "call_local")
func update_player_class(id, class_title):
	if StageManager.player_list.has(id):
		StageManager.player_list[id].class = class_title
	else:
		print("Doesn't Exist")
		return

func start_game():
	#if multiplayer.is_server():
	#	$SwapTimer.start()
	pass

func player_dead(id):
	players_alive -= 1
	main_ui.player_dead.rpc(id)
	game_node.player_dead.rpc(id)
	
	var winner_id = 1
	if players_alive == 1:
		for p in [player_1, player_2, player_3, player_4]:
			if is_instance_valid(p) and p.player_id != id:
				winner_id = p.player_id
				break
	
	await get_tree().process_frame
	clear_player(id)
	
	if players_alive == 1:
		await get_tree().process_frame
		end_match.rpc(winner_id)

@rpc ("any_peer", "call_local", "reliable")
func end_match(winner_id: int):
	players_alive = 0
	$SwapTimer.stop()
	$TransformTimer.stop()
	StageManager.update_game_state(StageManager.GameState.MATCH_OVER)
	
	await get_tree().process_frame
	
	StageManager.update_scores(winner_id)
	main_ui.match_over(winner_id)
	
	await get_tree().create_timer(6.0).timeout
		
	if StageManager.game_state != StageManager.GameState.GAME_OVER:
		prep_new_match()
	else:
		game_end()

@rpc("any_peer","call_local", "reliable")
func prep_new_match():
	player_1 = null
	player_2 = null
	player_3 = null
	player_4 = null
	
	clear_winner()
	game_node.clear_battlefield()
	
	await get_tree().create_timer(0.5).timeout
	
	if multiplayer.is_server(): new_game()


@rpc("any_peer", "call_local", "reliable")
func clear_player(id):
	var number = StageManager.get_player_number(id)
	var p_node = null
	
	match number:
		1: 
			p_node = player_1
			player_1 = null
		2: 
			p_node = player_2
			player_2 = null
		3: 
			p_node = player_3
			player_3 = null
		4: 
			p_node = player_4
			player_4 = null
		
	if is_instance_valid(p_node):
		var sync_node = p_node.get_node_or_null("PlayerSynchronizer")
		if sync_node:
			sync_node.public_visibility = false
			sync_node.process_mode = PROCESS_MODE_DISABLED
		
		if multiplayer.is_server():
			await get_tree().process_frame
			await get_tree().process_frame
			p_node.queue_free()
		else:
			pass

func clear_winner():
	await get_tree().process_frame # In case dead players aren't cleared
	
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		if is_instance_valid(p) and not p.is_queued_for_deletion():
			var sync_node = p.get_node_or_null("PlayerSynchronizer")
			if sync_node:
				sync_node.public_visibility = false
				sync_node.process_mode = PROCESS_MODE_DISABLED
	
	if multiplayer.is_server():
		await get_tree().process_frame
		for p in players:
			if is_instance_valid(p) and not p.is_queued_for_deletion():
				p.queue_free()

@rpc("any_peer","call_local","reliable")
func new_game():
	create_players()
	await get_tree().process_frame
	await get_tree().process_frame
	sync_new_match.rpc()

@rpc("any_peer","call_local","reliable")
func sync_new_match():
	assign_players()
	if is_instance_valid(player_1): update_player_class(player_1.player_id, "base")
	if is_instance_valid(player_2): update_player_class(player_2.player_id, "base")
	if player_count >= 3:
		if is_instance_valid(player_3): update_player_class(player_3.player_id, "base")
	if player_count >= 4:
		if is_instance_valid(player_4): update_player_class(player_4.player_id, "base")
	game_node.start_game()

@rpc("any_peer","call_local", "reliable")
func game_end():
	game_node.game_end()

func _on_swap_timer_timeout() -> void:
	class_change()
	$TransformTimer.start()

func _on_transform_timer_timeout() -> void:
	$SwapTimer.start()

func dev_class_change(class_title: String):
	var id = multiplayer.get_unique_id()
	var number = StageManager.get_player_number(id)
	match number:
		1:
			update_player_class.rpc(player_1.player_id, class_title)
			player_1.class_change.rpc(class_title)
			await player_1.child_entered_tree
		2:
			update_player_class.rpc(player_2.player_id, class_title)
			player_2.class_change.rpc(class_title)
			await player_2.child_entered_tree
		3:
			update_player_class.rpc(player_3.player_id, class_title)
			player_3.class_change.rpc(class_title)
			await player_3.child_entered_tree
		4:
			update_player_class.rpc(player_4.player_id, class_title)
			player_4.class_change.rpc(class_title)
			await player_4.child_entered_tree
	main_ui.class_change.rpc()

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
		

func _on_spawn_custom(data: Dictionary):
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
