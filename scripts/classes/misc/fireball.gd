extends Area2D

@export var speed: float = 300

var direction: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var mouse_pos: Vector2 = Vector2.ZERO

var damage: float = 0

func _ready() -> void:
	$AnimatedSprite2D.play()

func _process(delta: float) -> void:
	position += velocity * delta

func start_follow_timer():
	$FollowTimer.start()

func _on_area_entered(area: Area2D) -> void:
	if area.name == "Hurtbox":
		if area.get_parent().has_method("take_damage")\
		and area.get_parent().player_id != 1:
			area.get_parent().take_damage(damage)
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("dummy"):
		queue_free()
	elif body.is_in_group("environment"):
		queue_free()

func _on_follow_timer_timeout() -> void:
	mouse_pos = get_global_mouse_position()
	direction = position.direction_to(mouse_pos)
	rotation = direction.angle()
	velocity = direction * speed
