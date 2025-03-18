extends Node

var player_1: CharacterBody2D
var player_2: CharacterBody2D
var player_3: CharacterBody2D
var player_4: CharacterBody2D

func _ready() -> void:
	start_game()

func assign_players():
	var players = get_tree().get_nodes_in_group("players")
	player_1 = players[0]
	player_2 = players[1]
	if players.size() >= 3:
		player_3 = players[2]
	if players.size() >= 4:
		player_4 = players[3]

func start_game():
	StageManager.update_game_state("Starting Game")
	assign_players()
	player_1.is_paused = true
	player_2.is_paused = true
	if StageManager.player_count >= 3: player_3.is_paused = true
	if StageManager.player_count >= 4: player_4.is_paused = true
	
	$MainUI.start_game()
	
	await get_tree().create_timer(4).timeout
	
	player_1.smooth_camera("position")
	player_2.smooth_camera("position")
	if StageManager.player_count >= 3: player_3.smooth_camera("position")
	if StageManager.player_count >= 4: player_4.smooth_camera("position")
	player_1.reset_camera_focus()
	player_2.reset_camera_focus()
	if StageManager.player_count >= 3: player_3.reset_camera_focus()
	if StageManager.player_count >= 4: player_4.reset_camera_focus()
	player_1.zoom_camera(1.5)
	player_2.zoom_camera(1.5)
	if StageManager.player_count >= 3: player_3.zoom_camera(1.5)
	if StageManager.player_count >= 4: player_4.zoom_camera(1.5)
	
	await $MainUI/FX.animation_finished
	player_1.is_paused = false
	player_2.is_paused = false
	if StageManager.player_count >= 3: player_3.is_paused = false
	if StageManager.player_count >= 4: player_4.is_paused = false
	$GameManager.start_game()
	StageManager.update_game_state("In Game")

func game_end():
	$MainUI.game_end()
	
	await $MainUI/AnimationPlayer.animation_finished
	back_to_main_menu()

func back_to_main_menu():
	get_tree().current_scene.show()
	StageManager.reset_game()
	queue_free()

@rpc("any_peer","call_local","reliable")
func player_dead(id):
	match id:
		StageManager.p1_id:
			await player_1.tree_exiting
			play_ko_effect(player_1)
		StageManager.p2_id:
			await player_2.tree_exiting
			play_ko_effect(player_2)
		StageManager.p3_id:
			await player_3.tree_exiting
			play_ko_effect(player_3)
		StageManager.p4_id:
			await player_4.tree_exiting
			play_ko_effect(player_4)

func play_ko_effect(loser):
	var effects = $World/AreaFX.duplicate()
	$World.add_child(effects)
	if loser.global_position.y <= -150: # Top
		effects.global_position.y = -150
	elif loser.global_position.y > 1330: # Bottom
		effects.global_position.y = 1330
	else:
		effects.global_position.y = loser.global_position.y
	if loser.global_position.x <= -150: # Left
		effects.global_position.x = -150
	elif loser.global_position.x > 2070: # Right
		effects.global_position.x = 2070
	else:
		effects.global_position.x = loser.global_position.x
	effects.global_rotation = effects.global_position.direction_to($World/MapCenter.global_position).angle()
	effects.show()
	effects.play("ko")
	await effects.animation_finished
	effects.queue_free()

@rpc("any_peer","call_local")
func spawn(new_node: Node):
	$Summons.add_child(new_node)

@rpc("any_peer","call_local")
func clear_summons():
	var summons = $Summons.get_children()
	for i in summons:
		i.queue_free()
