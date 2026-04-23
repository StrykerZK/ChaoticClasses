extends Node

var player_1: CharacterBody2D
var player_2: CharacterBody2D
var player_3: CharacterBody2D
var player_4: CharacterBody2D
var local_player: CharacterBody2D

# World's children
var areaFX: AnimatedSprite2D
var mapCenter: Marker2D

# Camera
var camera_target: Node2D = null
var camera_base_zoom: float = 0.7

# Spectating
var is_spectating: bool = false
var match_ending: bool = false # Only for last player spectating

func _ready() -> void:
	
	# --- NODE ASSIGNMENT ---
	for i in $World.get_children(): 
		match i.name:
			"AreaFX": areaFX = i
			"MapCenter": mapCenter = i
	
	# --- Start of Game ---
	if multiplayer.is_server():
		$MultiplayerManager.create_players()

func _process(delta) -> void:
	if is_spectating:
		if Input.is_action_just_pressed("move_left"):
			cycle_spectator(-1)
		if Input.is_action_just_pressed("move_right"):
			cycle_spectator(1)
	
	if is_instance_valid(camera_target):
		$Camera.global_position = camera_target.global_position
	else:
		if is_spectating: cycle_spectator()
		else:
			if $Camera.zoom != Vector2(camera_base_zoom, camera_base_zoom): zoom_camera(camera_base_zoom)
			$Camera.global_position = mapCenter.global_position

func assign_players(): # Assign player nodes for ref
	for player in get_tree().get_nodes_in_group("players"):
		for i in StageManager.player_list:
			if player.name.to_int() != i: continue
			match StageManager.player_list[i].number:
				1: player_1 = player
				2: player_2 = player
				3: player_3 = player
				4: player_4 = player
	
	var local_id = multiplayer.get_unique_id()
	
	for p in [player_1, player_2, player_3, player_4]:
		if is_instance_valid(p) and p.player_id == local_id:
			local_player = p
			break

func start_game(): # Start of match effects
	StageManager.update_game_state(StageManager.GameState.STARTING)
	if is_spectating: is_spectating = false
	if match_ending: match_ending = false
	assign_players()
	
	pause_players()
	invul_players(5.0)
	
	$MainUI.start_game()
	
	await get_tree().create_timer(4).timeout
	
	set_camera_target(local_player)
	zoom_camera(1.5)
	
	await $MainUI/FX.animation_finished
	unpause_players()
	$MultiplayerManager.start_game()
	StageManager.update_game_state(StageManager.GameState.IN_GAME)

func end_game():
	$MainUI.end_game()
	
	await $MainUI/AnimationPlayer.animation_finished
	back_to_main_menu()

func back_to_main_menu():
	get_tree().current_scene.show_main_menu()
	StageManager.reset_game()
	NetworkManager.clear()
	queue_free()

@rpc("any_peer","call_local","reliable")
func player_dead(id):
	if !is_spectating:
		if !match_ending:
			if id == local_player.player_id: 
				is_spectating = true
				cycle_spectator()
	
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

func cycle_spectator(direction: int = 1):
	var alive_players = get_tree().get_nodes_in_group("players")
	
	if alive_players.size() <= 1: return
	
	var current_index = alive_players.find(camera_target)
	
	var next_index = (current_index + direction + alive_players.size()) % alive_players.size()
	
	set_camera_target(alive_players[next_index])

func last_player_dead(id: int):
	var last_player = null
	is_spectating = false
	match_ending = true
	
	for p in [player_1, player_2, player_3, player_4]:
		if is_instance_valid(p) and p.player_id == id:
			last_player = p
			break
	
	if is_instance_valid(last_player):
		set_camera_target(last_player)
		zoom_camera(2.5)
		Engine.time_scale = 0.1
		await get_tree().create_timer(0.15).timeout
		Engine.time_scale = 1
		camera_target = null
		zoom_camera(1.0)

func play_ko_effect(loser):
	var effects = areaFX.duplicate()
	$World.add_child(effects)
	var map_limits: Vector2 = MapManager.get_map_limits()
	var fx_x = clamp(loser.global_position.x, -map_limits.x, map_limits.x)
	var fx_y = clamp(loser.global_position.y, -map_limits.y, map_limits.y)
	effects.global_position = Vector2(fx_x,fx_y)
	
	effects.global_rotation = effects.global_position.direction_to(Vector2.ZERO).angle()
	effects.show()
	effects.play("ko")
	
	await effects.animation_finished
	effects.queue_free()

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

func set_camera_target(new_target: Node2D):
	camera_target = new_target

func zoom_camera(amount: float, duration: float = 0.5):
	# $Camera.zoom = Vector2(amount,amount) ORIGINAL
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property($Camera, "zoom", Vector2(amount, amount), duration)

func smooth_camera(setting: String):
	if setting == "limit":
		$Camera.limit_smoothed = !$Camera.limit_smoothed
	elif setting == "position":
		$Camera.position_smoothing_enabled = !$Camera.position_smoothing_enabled
		if $Camera.position_smoothing_enabled:
			$Camera.position_smoothing_speed = 3
	elif setting == "rotation":
		$Camera.rotation_smoothing_enabled = !$Camera.rotation_smoothing_enabled
