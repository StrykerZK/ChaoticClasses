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

func _process(delta) -> void:
	if is_instance_valid(camera_target):
		$Camera.global_position = camera_target.global_position
	else:
		$Camera.global_position = mapCenter.global_position

func assign_local_player() -> void:
	local_player = get_tree().get_first_node_in_group("players")

func start_swarm_game() -> void:
	pass

func game_end() -> void:
	back_to_main_menu()

func back_to_main_menu() -> void:
	get_tree().current_scene.show_main_menu()
	StageManager.reset_game()
	queue_free()
