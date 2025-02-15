extends Node

func _ready() -> void:
	
	$AnimationPlayer.play("start_game")
	
	await get_tree().create_timer(4).timeout
	
	$Camera2D.queue_free()
	
	
