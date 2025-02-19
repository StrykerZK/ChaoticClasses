extends Node2D


func detect_exit(body: Node2D) -> void:
	print("DETECTED")
	if body.is_in_group("players"):
		print("IT'S "+str(body.name))
		$AnimatedSprite2D.position = body.position
		var angle = body.velocity.angle()
		$AnimatedSprite2D.rotation = -angle
		$AnimatedSprite2D.play("ko")
