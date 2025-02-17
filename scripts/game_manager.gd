extends Node

signal paused(is_paused)

var transform_time: float = 2

var is_paused = false

var player_spawn: Node
var player_manager: Node
var player_1: CharacterBody2D
var player_2: CharacterBody2D
var player_count = 0

func _ready():
	player_manager = get_node("/root/Main/PlayerManager")
	
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

func game_start():
	if multiplayer.is_server():
		$SwapTimer.start()

func game_over(id):
	$SwapTimer.stop()
	await get_tree().create_timer(4).timeout
	toggle_pause()

func _on_swap_timer_timeout() -> void:
	class_change()
	$SwapTimer.start()
