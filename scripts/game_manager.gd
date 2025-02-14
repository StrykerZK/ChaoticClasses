extends Node

signal paused(is_paused)

var transform_time: float = 2

var is_paused = false

var player_spawn: Node
var player_manager: Node
var player_1: CharacterBody2D
var player_2: CharacterBody2D
var player_1_class: String = "Base"
var player_2_class: String = "Base"

func _ready():
	player_manager = get_node("/root/Main/PlayerManager")
	assign_players.rpc()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		toggle_pause.rpc()

func _process(delta: float) -> void:
	pass

@rpc("any_peer","call_local")
func assign_players():
	var players = get_tree().get_nodes_in_group("players")
	player_1 = players[0]
	player_2 = players[1]

@rpc("any_peer","call_local")
func change_class():
	toggle_pause()
	
	# Randomize and get two new classes
	var class_count = ClassManager.get_class_count() - 1
	var class_index_1 = randi_range(1, class_count)
	var class_index_2 = randi_range(1, class_count)
	var class_title_1 = ClassManager.get_class_title(class_index_1)
	while class_title_1 == player_1_class:
		class_title_1 = ClassManager.get_class_title(class_index_1)
	var class_title_2 = ClassManager.get_class_title(class_index_2)
	while class_title_2 == player_2_class:
		class_title_2 = ClassManager.get_class_title(class_index_2)
	
	# Update current class names
	player_1_class = class_title_1
	player_2_class = class_title_2
	
	
	# Run class_change() method in players
	player_1.class_change.rpc(class_title_1, transform_time)
	player_2.class_change.rpc(class_title_2, transform_time)
	
	# Instantiate the new classes
	var class_node_1 = load("res://classes/" + class_title_1 + ".tscn").instantiate()
	var class_node_2 = load("res://classes/" + class_title_2 + ".tscn").instantiate()
	
	# Add new class nodes as children for players
	player_1.add_child(class_node_1)
	player_2.add_child(class_node_2)
	
	# Move new class nodes to top of children
	player_1.move_child(class_node_1, 0)
	player_2.move_child(class_node_2, 0)
	
	await get_tree().create_timer(transform_time + 0.05).timeout
	toggle_pause()

@rpc("authority","call_local")
func toggle_pause():
	
	# ADD CONDITIONS FOR OTHER PLAYER PAUSE, CLASS SWAPPING, ETC.
	
	get_tree().paused = !get_tree().paused
	is_paused = !is_paused
	paused.emit()


func _on_button_pressed() -> void:
	change_class.rpc()
