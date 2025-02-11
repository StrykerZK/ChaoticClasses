extends Node

signal paused(is_paused)

var is_paused = false

var player_1: CharacterBody2D
var player_2: CharacterBody2D

func _ready():
	# Connect these two to multiplayer node
	player_1 = get_node("/root/Main/PlayerManager/Player")
	paused.connect(Callable(player_1, "toggle_paused"))
	#paused.connect(Callable(player_2, "toggle_paused"))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		toggle_pause()

func toggle_pause():
	
	# ADD CONDITIONS FOR OTHER PLAYER PAUSE, CLASS SWAPPING, ETC.
	
	get_tree().paused = !get_tree().paused
	is_paused = !is_paused
	paused.emit()
