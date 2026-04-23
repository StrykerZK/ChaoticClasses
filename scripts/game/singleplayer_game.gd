extends Node

var local_player: CharacterBody2D

# World's children
var areaFX: AnimatedSprite2D
var mapCenter: Marker2D

# Camera
var camera_target: Node2D = null
var camera_base_zoom: float = 0.7

func _ready() -> void:
	
	# --- NODE ASSIGNMENT ---
	for i in $World.get_children(): 
		match i.name:
			"AreaFX": areaFX = i
			"MapCenter": mapCenter = i
	
	start_game()

func _process(delta) -> void:
	if is_instance_valid(camera_target):
		$Camera.global_position = camera_target.global_position
	else:
		$Camera.global_position = mapCenter.global_position

func assign_local_player() -> void:
	local_player = get_tree().get_first_node_in_group("players")

func start_game() -> void:
	$SingleplayerManager.spawn_player()
	
	StageManager.update_game_state(StageManager.GameState.STARTING)
	
	$MainUI.start_game()
	
	await get_tree().create_timer(4).timeout
	
	set_camera_target(local_player)
	zoom_camera(1.5)
	
	await $MainUI/FX.animation_finished
	$SingleplayerManager.start_game()
	StageManager.update_game_state(StageManager.GameState.IN_GAME)

func assign_player() -> void:
	local_player = get_tree().get_first_node_in_group("players")

func game_end() -> void:
	back_to_main_menu()

func back_to_main_menu() -> void:
	get_tree().current_scene.show_main_menu()
	StageManager.reset_game()
	NetworkManager.clear()
	queue_free()

func player_dead(id: int) -> void:
	if is_instance_valid(local_player):
		zoom_camera(2.5)
		Engine.time_scale = 0.1
		await get_tree().create_timer(0.15).timeout
		Engine.time_scale = 1
		zoom_camera(1.0)

func play_ko_effect(loser) -> void:
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

func pause_player() -> void:
	local_player.is_paused = true

func unpause_players() -> void:
	local_player.is_paused = false

func invul_players(time: float) -> void:
	local_player.activate_i_frame(time)

func clear_battlefield() -> void:
	clear_projectiles()
	clear_spells()
	clear_summons()

func clear_projectiles() -> void:
	for i in get_tree().get_nodes_in_group("projectiles"):
		i.queue_free()

func clear_spells() -> void:
	for i in get_tree().get_nodes_in_group("spells"):
		i.queue_free()

func clear_summons() -> void:
	for i in get_tree().get_nodes_in_group("summons"):
		i.queue_free()

func set_camera_target(new_target: Node2D) -> void:
	camera_target = new_target

func zoom_camera(amount: float, duration: float = 0.5) -> void:
	# $Camera.zoom = Vector2(amount,amount) ORIGINAL
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property($Camera, "zoom", Vector2(amount, amount), duration)

func smooth_camera(setting: String) -> void:
	if setting == "limit":
		$Camera.limit_smoothed = !$Camera.limit_smoothed
	elif setting == "position":
		$Camera.position_smoothing_enabled = !$Camera.position_smoothing_enabled
		if $Camera.position_smoothing_enabled:
			$Camera.position_smoothing_speed = 3
	elif setting == "rotation":
		$Camera.rotation_smoothing_enabled = !$Camera.rotation_smoothing_enabled
