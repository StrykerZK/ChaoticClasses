extends Node

signal player_loaded

@export var player_scene: PackedScene

var transform_time: float = 2

var is_paused: bool = false
var pause_id: int

# Player Management
var local_player: CharacterBody2D

# Player Spawning
var player_spawner: MultiplayerSpawner
var spawned_count: int = 0

var main_ui: CanvasLayer
var game_node: Node
var world_node: Node2D

func _ready() -> void:
	game_node = get_parent()
	main_ui = $"../MainUI"
	world_node = $"../World"
	player_spawner = world_node.get_player_spawner()
	
	player_loaded.connect(Callable(game_node,"assign_player"))
	player_loaded.connect(Callable(self,"assign_player"))
	player_loaded.connect(Callable(main_ui,"assign_player"))
	
	player_spawner.spawn_function = _on_spawn_custom
	player_spawner.spawned.connect(_on_player_spawned)
	
	
func _input(event: InputEvent) -> void:
	if StageManager.game_state == StageManager.GameState.IN_GAME:
		if event.is_action_pressed("back"):
			toggle_pause.rpc(multiplayer.get_unique_id())

func assign_player() -> void:
	local_player = get_tree().get_first_node_in_group("players")

@rpc("any_peer")
func class_change() -> void:	
	StageManager.update_game_state.rpc(StageManager.GameState.TRANSFORMING)
	
	# Randomize and get new class
	var class_title: String = ClassManager.get_random_class(local_player.player_id)
	
	# Update StageManager's player_list
	update_player_class(local_player.player_id, class_title)
	
	# Run class_change() method in players
	local_player.class_change(class_title)
	
	# Update player info
	await local_player.child_entered_tree
	main_ui.class_change()

@rpc("any_peer","call_local")
func toggle_pause(id: int) -> void: # id == 0 means non-player pausing
	is_paused = !is_paused
	get_tree().paused = !get_tree().paused
	local_player.toggle_pause()
	$SwapTimer.paused = !$SwapTimer.paused
	main_ui.toggle_pause()

@rpc("any_peer", "call_local")
func update_player_class(id: int, class_title: String) -> void:
	if StageManager.player_list.has(id):
		StageManager.player_list[id].class = class_title
	else:
		print("Doesn't Exist")
		return

func start_game() -> void:
	$SwapTimer.start()

func player_dead(id: int) -> void:
	main_ui.player_dead(id)
	game_node.player_dead(id)
	
	await get_tree().process_frame
	
	clear_player()
	end_game()

func end_game() -> void:
	$SwapTimer.stop()
	$TransformTimer.stop()
	StageManager.update_game_state(StageManager.GameState.GAME_OVER)
	
	await get_tree().process_frame
	
	main_ui.solo_end_game()
	
	await get_tree().create_timer(6.0).timeout
	
	game_node.end_game()

func clear_player() -> void:
	if is_instance_valid(local_player):
		var sync_node = local_player.get_node_or_null("PlayerSynchronizer")
		if sync_node:
			sync_node.public_visibility = false
			sync_node.process_mode = PROCESS_MODE_DISABLED
		
		local_player.queue_free()
		
	local_player = null

func new_game():
	pass

func _on_swap_timer_timeout() -> void:
	class_change()
	$TransformTimer.start()

func _on_transform_timer_timeout() -> void:
	$SwapTimer.start()

func dev_class_change(class_title: String) -> void:
	update_player_class(local_player.player_id, class_title)
	local_player.class_change(class_title)
	main_ui.class_change()

func spawn_player() -> void:
	var new_player = player_spawner.spawn({
		"pos": get_parent().mapCenter.global_position
	})
	_on_player_spawned(new_player)
	

func _on_spawn_custom(data: Dictionary):
	var p = player_scene.instantiate()
	p.name = "1"
	p.global_position = data.pos
	return p

func _on_player_spawned(_node) -> void:
	await get_tree().process_frame
	player_loaded.emit()
