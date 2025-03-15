extends Node

signal paused(is_paused)

var transform_time: float = 2

var is_paused: bool = false
var pause_id: int

var player_manager: Node
var player_1: CharacterBody2D
var player_2: CharacterBody2D
var player_3: CharacterBody2D
var player_4: CharacterBody2D
var player_count: int = 0
var players_alive: int = 0

var main_ui: CanvasLayer
var main_node: Node

func _ready():
	player_manager = get_node("/root/Main/PlayerManager")
	main_ui = get_node("/root/Main/MainUI")
	main_node = get_parent()
	player_count = StageManager.player_count
	
func _input(event: InputEvent) -> void:
	if StageManager.game_state != "Starting Game"\
	and StageManager.game_state != "Match Over"\
	and StageManager.game_state != "Transforming"\
	and StageManager.game_state != "Game Over":
		if event.is_action_pressed("back"):
			toggle_pause.rpc(multiplayer.get_unique_id())

func _process(delta: float) -> void:
	pass

func _on_players_connected():
	players_alive += 1
	if players_alive == StageManager.player_list.size():
		assign_players.rpc()
		$/root/Main/MainUI.assign_players.rpc()

@rpc("any_peer","call_local")
func assign_players():
	var players = get_tree().get_nodes_in_group("players")
	player_1 = players[0]
	player_2 = players[1]
	if players.size() >= 3:
		player_3 = players[2]
	if players.size() >= 4:
		player_4 = players[3]

@rpc("any_peer")
func class_change():	
	StageManager.update_game_state.rpc("Transforming")
	
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
	
	# For 3 and 4 players
	if player_count >= 3:
		var class_title_3 = ClassManager.get_random_class(player_3.player_id)
		while class_title_3 == class_title_1 and class_title_3 == class_title_2:
			class_title_3 = ClassManager.get_random_class(player_3.player_id)
		update_player_class.rpc(player_3.player_id, class_title_3)
		player_3.class_change.rpc(class_title_3)
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
func toggle_pause(id: int): # Use 0 as id for standard rpc calling
	if id != 0:
		if !is_paused:
			pause_id = id
		else:
			if id != pause_id:
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
	if StageManager.game_state == "In Game":
		main_ui.toggle_pause()

@rpc("any_peer", "call_local")
func update_player_class(id, class_title):
	if StageManager.player_list.has(id):
		StageManager.player_list[id].class = class_title
	else:
		print("Doesn't Exist")
		return

func start_game():
	pass
	#if multiplayer.is_server():
	#	$SwapTimer.start()

func player_dead(id):
	players_alive -= 1
	main_ui.player_dead.rpc(id)
	main_node.player_dead.rpc(id)
	clear_player.rpc(id)
	
	if players_alive == 1:
		$SwapTimer.stop()
		$TransformTimer.stop()
		await get_tree().create_timer(0.1).timeout
		var winner_id = player_manager.get_child(1).name.to_int()
		StageManager.update_game_state.rpc("Match Over")
		StageManager.update_scores.rpc(winner_id)
		main_ui.match_over.rpc(winner_id)
		
		await get_tree().create_timer(6).timeout
		if StageManager.game_state != "Game Over":
			clear_player.rpc(winner_id)
			players_alive -= 1
			main_node.clear_summons.rpc()
			# await player exited code
			await get_tree().create_timer(0.01).timeout
			new_game.rpc()
		else:
			game_end.rpc()

@rpc("any_peer", "call_local", "reliable")
func clear_player(id):
	match id:
		StageManager.p1_id: player_1.queue_free()
		StageManager.p2_id: player_2.queue_free()
		StageManager.p3_id: player_3.queue_free()
		StageManager.p4_id: player_4.queue_free()

@rpc("any_peer","call_local","reliable")
func new_game():
	player_manager.create_players()
	assign_players()
	update_player_class(player_1.player_id, "base")
	update_player_class(player_2.player_id, "base")
	if player_count >= 3:
		update_player_class(player_3.player_id, "base")
	if player_count >= 4:
		update_player_class(player_4.player_id, "base")
	get_parent().start_game()

@rpc("any_peer","call_local", "reliable")
func game_end():
	get_parent().game_end()

func _on_swap_timer_timeout() -> void:
	class_change()
	$TransformTimer.start()

func _on_transform_timer_timeout() -> void:
	$SwapTimer.start()

func dev_class_change(class_title: String):
	var id = multiplayer.get_unique_id()
	if id == StageManager.p1_id:
		update_player_class.rpc(player_1.player_id, class_title)
		player_1.class_change.rpc(class_title)
		await player_1.child_entered_tree
	elif id == StageManager.p2_id:
		update_player_class.rpc(player_2.player_id, class_title)
		player_2.class_change.rpc(class_title)
		await player_2.child_entered_tree
	elif id == StageManager.p3_id:
		update_player_class.rpc(player_3.player_id, class_title)
		player_3.class_change.rpc(class_title)
		await player_3.child_entered_tree
	elif id == StageManager.p4_id:
		update_player_class.rpc(player_4.player_id, class_title)
		player_4.class_change.rpc(class_title)
		await player_4.child_entered_tree
	main_ui.class_change.rpc()
