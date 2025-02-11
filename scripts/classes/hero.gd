extends Node2D

@onready var player: CharacterBody2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_parent()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func attack():
	pass


func _on_combo_timer_timeout() -> void:
	player.is_attacking = false
