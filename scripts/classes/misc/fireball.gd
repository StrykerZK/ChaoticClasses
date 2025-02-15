extends Projectile

@export var fireball_speed: float = 300

func _ready() -> void:
	$AnimatedSprite2D.play()
	speed = fireball_speed
	area_entered.connect(Callable(self,"_on_area_entered"))
	body_entered.connect(Callable(self,"_on_body_entered"))

func start_follow_timer():
	$FollowTimer.start()

func _on_follow_timer_timeout() -> void:
	direction = position.direction_to(mouse_pos)
	rotation = direction.angle()
	velocity = direction * speed
