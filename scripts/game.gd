extends Node

var player_1: CharacterBody2D
var player_2: CharacterBody2D
var player_3: CharacterBody2D
var player_4: CharacterBody2D

var world: Node
var areaFX: AnimatedSprite2D

func _ready() -> void:
	
	# --- NODE ASSIGNMENT ---
	world = get_child(0)
	for i in world.get_children(): 
		if i.name == "AreaFX": 
			areaFX = i
			break
	
	# --- Start of Game ---
	if multiplayer.is_server():
		$PlayerManager.create_players()

func assign_players(): # Assign player nodes for ref
	for player in get_tree().get_nodes_in_group("players"):
		for i in StageManager.player_list:
			if player.name.to_int() != i: continue
			match StageManager.player_list[i].number:
				1: player_1 = player
				2: player_2 = player
				3: player_3 = player
				4: player_4 = player

func start_game(): # Start of match effects
	StageManager.update_game_state("Starting Game")
	assign_players()
	
	pause_players()
	invul_players(5.0)
	
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
	unpause_players()
	$GameManager.start_game()
	StageManager.update_game_state("In Game")

func game_end():
	$MainUI.game_end()
	
	await $MainUI/AnimationPlayer.animation_finished
	back_to_main_menu()

func back_to_main_menu():
	get_tree().current_scene.show_main_menu()
	StageManager.reset_game()
	queue_free()

@rpc("any_peer","call_local","reliable")
func player_dead(id):
	var number = StageManager.get_player_number(id)
	match number:
		1:
			await player_1.tree_exiting
			play_ko_effect(player_1)
		2:
			await player_2.tree_exiting
			play_ko_effect(player_2)
		3:
			await player_3.tree_exiting
			play_ko_effect(player_3)
		4:
			await player_4.tree_exiting
			play_ko_effect(player_4)

func play_ko_effect(loser):
	var effects = areaFX.duplicate()
	world.add_child(effects)
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
	effects.global_rotation = effects.global_position.direction_to(world.get_child(3).global_position).angle() # MapCenter node index 3
	effects.show()
	effects.play("ko")
	await effects.animation_finished
	effects.queue_free()

@rpc("any_peer","call_local")
func spawn(new_node: Node):
	$Summons.add_child(new_node)

func pause_players():
	player_1.is_paused = true
	player_2.is_paused = true
	if StageManager.player_count >= 3: player_3.is_paused = true
	if StageManager.player_count >= 4: player_4.is_paused = true

func unpause_players():
	player_1.is_paused = false
	player_2.is_paused = false
	if StageManager.player_count >= 3: player_3.is_paused = false
	if StageManager.player_count >= 4: player_4.is_paused = false

func invul_players(time: float):
	player_1.activate_i_frame(time)
	player_2.activate_i_frame(time)
	if StageManager.player_count >= 3: player_3.activate_i_frame(time)
	if StageManager.player_count >= 4: player_4.activate_i_frame(time)

func clear_battlefield():
	clear_projectiles()
	clear_spells()
	clear_summons()

func clear_projectiles():
	for i in get_tree().get_nodes_in_group("projectiles"):
		i.queue_free()

func clear_spells():
	for i in get_tree().get_nodes_in_group("spells"):
		i.queue_free()

func clear_summons():
	for i in get_tree().get_nodes_in_group("summons"):
		i.queue_free()
