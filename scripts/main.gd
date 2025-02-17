extends Node

var player_1
var player_2

func _ready() -> void:
	
	StageManager.update_game_state.rpc("Starting Game")
	
	assign_players()
	$AnimationPlayer.play("start_game")
	
	await get_tree().create_timer(4).timeout
	
	$Camera2D.queue_free()
	
	await $AnimationPlayer.animation_finished
	player_1.is_paused = false
	player_2.is_paused = false
	$GameManager.game_start()
	StageManager.update_game_state.rpc("In Match")

func assign_players():
	var players = get_tree().get_nodes_in_group("players")
	player_1 = players[0]
	player_2 = players[1]
