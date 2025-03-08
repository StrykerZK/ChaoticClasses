extends AnimatedSprite2D

func _process(delta: float) -> void:
	check_rotation()

func check_rotation():
	if rotation_degrees >= 270:
		rotation_degrees -= 360
	elif rotation_degrees <= -270:
		rotation_degrees += 360
	if rotation_degrees > 90 or rotation_degrees < -90:
		flip_v = true
	else:
		flip_v = false
