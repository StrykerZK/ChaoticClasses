extends Node

signal paused(is_paused)

var transform_time: float = 2

var is_paused = false

var player_spawn: Node
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
			toggle_pause.rpc()

func _process(delta: float) -> void:
	pass

func _on_players_connected():
	player_count += 1
	if player_count == StageManager.player_list.size():
		assign_players.rpc()

@rpc("any_peer","call_local")
func assign_players():
	var players = get_tree().get_nodes_in_group("players")
	player_1 = players[0]
	player_2 = players[1]

@rpc("any_peer")
func class_change():
	toggle_pause.rpc()
	
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
	main_ui.class_change.rpc()

@rpc("any_peer","call_local")
func toggle_pause():
	# ADD CONDITIONS FOR OTHER PLAYER PAUSE, CLASS SWAPPING, ETC.
	get_tree().paused = !get_tree().paused
	is_paused = !is_paused
	if is_instance_valid(player_1):
		player_1.toggle_pause()
	if is_instance_valid(player_2):
		player_2.toggle_pause()
	$SwapTimer.paused = !$SwapTimer.paused

func _on_button_pressed() -> void:
	if multiplayer.is_server():
		class_change()
		$SwapTimer.stop()
		$SwapTimer.start()
	else:
		class_change.rpc_id(1)
	$Button.release_focus()

@rpc("any_peer", "call_local")
func update_player_class(id, class_title):
	if StageManager.player_list.has(id):
		StageManager.player_list[id].class = class_title
	else:
		print("Doesn't Exist")
		return

func start_game():
	if multiplayer.is_server():
		$SwapTimer.start()

func game_over(id):
	if multiplayer.is_server():
		$SwapTimer.stop()
		StageManager.update_game_state.rpc("Game Over")
	await get_tree().create_timer(7).timeout
	if StageManager.p1_score != 3 and StageManager.p2_score != 3:
		clear_winner(id)
		if id == 1:
			await player_2.tree_exited
		else:
			await player_1.tree_exited
		new_game()
	else:
		game_end()

func _on_swap_timer_timeout() -> void:
	class_change()
	$SwapTimer.start()

@rpc("any_peer","call_local")
func clear_winner(loser_id):
	if loser_id == 1:
		player_2.queue_free()
	else:
		player_1.queue_free()

@rpc("any_peer","call_local")
func new_game():
	player_manager.spawn_players()
	assign_players()
	update_player_class(player_1.player_id, "Base")
	update_player_class(player_2.player_id, "Base")
	get_parent().start_game()

@rpc("any_peer","call_local")
func game_end():
	get_parent().game_end()
