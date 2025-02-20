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
	
	$MainUI.start_game()
	
	await get_tree().create_timer(4).timeout
	assign_players()
	player_1.zoom_camera(1.5)
	player_2.zoom_camera(1.5)
	player_1.smooth_camera("limit")
	player_2.smooth_camera("limit")
	
	await $MainUI/FX.animation_finished
	player_1.is_paused = false
	player_2.is_paused = false
	$GameManager.start_game()
	StageManager.update_game_state("In Match")

func game_end():
	StageManager.update_game_state("Game Ended")
	
	$MainUI.game_end()
	
	await $MainUI/AnimationPlayer.animation_finished
	back_to_main_menu()

func back_to_main_menu():
	get_tree().current_scene.show()
	StageManager.reset_game()
	queue_free()
	
