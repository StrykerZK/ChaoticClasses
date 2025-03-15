extends Projectile

@export var fireball_speed: float = 500

var is_spell_1: bool = false
var center_point: Vector2 = Vector2.ZERO

func _ready() -> void:
	$AnimatedSprite2D.play()
	speed = fireball_speed
	area_entered.connect(Callable(self,"_on_area_entered"))
	body_entered.connect(Callable(self,"_on_body_entered"))

func _process(delta: float) -> void:
	if is_spell_1:
		direction = direction.rotated(6.2 * delta)
		position = center_point + direction * 60.0
		rotation = direction.angle() + PI/2
	else:
		position += velocity * delta

func start_follow_timer():
	$FollowTimer.start()

func _on_follow_timer_timeout() -> void:
	direction = position.direction_to(mouse_pos)
	rotation = direction.angle()
	velocity = direction * speed

func _on_life_timer_timeout() -> void:
	queue_free()
