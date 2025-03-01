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
	player_1.smooth_camera("position")
	player_2.smooth_camera("position")
	player_1.reset_camera_focus()
	player_2.reset_camera_focus()
	player_1.zoom_camera(1.5)
	player_2.zoom_camera(1.5)
	
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

@rpc("any_peer","call_local","reliable")
func game_over(id):
	if id == StageManager.p1_id:
		await player_1.tree_exiting
		play_ko_effect(player_1, player_2)
	else:
		await player_2.tree_exiting
		play_ko_effect(player_2, player_1)

func play_ko_effect(loser, winner):
	if loser.global_position.y <= -150: # Top
		$World/AreaFX.global_position.y = -150
	elif loser.global_position.y > 1330: # Bottom
		$World/AreaFX.global_position.y = 1330
	else:
		$World/AreaFX.global_position.y = loser.global_position.y
	if loser.global_position.x <= -150: # Left
		$World/AreaFX.global_position.x = -150
	elif loser.global_position.x > 2070: # Right
		$World/AreaFX.global_position.x = 2070
	else:
		$World/AreaFX.global_position.x = loser.global_position.x
	$World/AreaFX.global_rotation = $World/AreaFX.global_position.direction_to(winner.global_position).angle()
	$World/AreaFX.show()
	$World/AreaFX.play("ko")
