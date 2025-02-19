extends Node

var player_1
var player_2

func _ready() -> void:
	start_game()
	

func assign_players():
	var players = get_tree().get_nodes_in_group("players")
	player_1 = players[0]
	player_2 = players[1]

func start_game():
	StageManager.update_game_state("Starting Game")
	
	assign_players()
	$AnimationPlayer.play("start_game")
	
	await get_tree().create_timer(4).timeout
	
	$Camera2D.queue_free() # Remove Camera to snap to players
	
	await $AnimationPlayer.animation_finished
	player_1.is_paused = false
	player_2.is_paused = false
	$GameManager.start_game()
	$MainUI.start_game()
	StageManager.update_game_state("In Match")
