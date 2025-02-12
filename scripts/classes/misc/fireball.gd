extends Area2D

@export var speed: float = 300

var direction: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var mouse_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	$AnimatedSprite2D.play()

func _process(delta: float) -> void:
	position += velocity * delta

func start_follow_timer():
	$FollowTimer.start()

func _on_area_entered(area: Area2D) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("environment"):
		queue_free()

func _on_follow_timer_timeout() -> void:
	mouse_pos = get_global_mouse_position()
	direction = position.direction_to(mouse_pos)
	rotation = direction.angle()
	velocity = direction * speed
