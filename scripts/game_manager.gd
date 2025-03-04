extends Node

signal paused(is_paused)

var transform_time: float = 2

var is_paused = false
var pause_id: int

var player_manager: Node
var player_1: CharacterBody2D
var player_2: CharacterBody2D
var player_count = 0

var main_ui: CanvasLayer

func _ready():
	player_manager = get_node("/root/Main/PlayerManager")
	main_ui = get_node("/root/Main/MainUI")
	
func _input(event: InputEvent) -> void:
	if StageManager.game_state != "Starting Game"\
	and StageManager.game_state != "Game Over"\
	and StageManager.game_state != "Transforming":
		if event.is_action_pressed("back"):
			toggle_pause.rpc(multiplayer.get_unique_id())

func _process(delta: float) -> void:
	pass

func _on_players_connected():
	player_count += 1
	if player_count == StageManager.player_list.size():
		assign_players.rpc()
		$/root/Main/MainUI.assign_players.rpc()

@rpc("any_peer","call_local")
func assign_players():
	var players = get_tree().get_nodes_in_group("players")
	player_1 = players[0]
	player_2 = players[1]

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
	
	# Update player info
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

func game_over(id):
	$SwapTimer.stop()
	$TransformTimer.stop()
	StageManager.update_game_state.rpc("Game Over")
	StageManager.update_scores.rpc(id)
	main_ui.game_over.rpc(id)
	get_parent().game_over.rpc(id)
	clear_player.rpc(id)
	
	await get_tree().create_timer(7).timeout
	if StageManager.p1_score != 3 and StageManager.p2_score != 3:
		clear_winner.rpc(id)
		if id == StageManager.p1_id:
			await player_2.tree_exited
		else:
			await player_1.tree_exited
		await get_tree().create_timer(0.1).timeout
		new_game.rpc()
	else:
		game_end.rpc()

@rpc("any_peer", "call_local", "reliable")
func clear_player(id):
	if id == StageManager.p1_id:
		player_1.queue_free()
	else:
		player_2.queue_free()

@rpc("any_peer","call_local","reliable")
func clear_winner(loser_id):
	if loser_id == StageManager.p1_id:
		player_2.queue_free()
	else:
		player_1.queue_free()

@rpc("any_peer","call_local","reliable")
func new_game():
	player_manager.create_players()
	assign_players()
	update_player_class(player_1.player_id, "base")
	update_player_class(player_2.player_id, "base")
	get_parent().start_game()

@rpc("any_peer","call_local", "reliable")
func game_end():
	get_parent().game_end()

func _on_swap_timer_timeout() -> void:
	class_change()
	$TransformTimer.start()

func _on_transform_timer_timeout() -> void:
	$SwapTimer.start()

func change_base() -> void:
	var id = multiplayer.get_unique_id()
	if id == StageManager.p1_id:
		update_player_class.rpc(player_1.player_id, "base")
		player_1.class_change.rpc("base")
		await player_1.child_entered_tree
	elif id == StageManager.p2_id:
		update_player_class.rpc(player_2.player_id, "base")
		player_2.class_change.rpc("base")
		await player_2.child_entered_tree
	main_ui.class_change.rpc()

func change_hero() -> void:
	var id = multiplayer.get_unique_id()
	if id == StageManager.p1_id:
		update_player_class.rpc(player_1.player_id, "hero")
		player_1.class_change.rpc("hero")
		await player_1.child_entered_tree
	elif id == StageManager.p2_id:
		update_player_class.rpc(player_2.player_id, "hero")
		player_2.class_change.rpc("hero")
		await player_2.child_entered_tree
	main_ui.class_change.rpc()

func change_demon() -> void:
	var id = multiplayer.get_unique_id()
	if id == StageManager.p1_id:
		update_player_class.rpc(player_1.player_id, "demon")
		player_1.class_change.rpc("demon")
		await player_1.child_entered_tree
	elif id == StageManager.p2_id:
		update_player_class.rpc(player_2.player_id, "demon")
		player_2.class_change.rpc("demon")
		await player_2.child_entered_tree
	main_ui.class_change.rpc()

func change_pyro() -> void:
	var id = multiplayer.get_unique_id()
	if id == StageManager.p1_id:
		update_player_class.rpc(player_1.player_id, "pyromancer")
		player_1.class_change.rpc("pyromancer")
		await player_1.child_entered_tree
	elif id == StageManager.p2_id:
		update_player_class.rpc(player_2.player_id, "pyromancer")
		player_2.class_change.rpc("pyromancer")
		await player_2.child_entered_tree
	main_ui.class_change.rpc()

func change_archer() -> void:
	var id = multiplayer.get_unique_id()
	if id == StageManager.p1_id:
		update_player_class.rpc(player_1.player_id, "archer")
		player_1.class_change.rpc("archer")
		await player_1.child_entered_tree
	elif id == StageManager.p2_id:
		update_player_class.rpc(player_2.player_id, "archer")
		player_2.class_change.rpc("archer")
		await player_2.child_entered_tree
	main_ui.class_change.rpc()
