extends Projectile

@export var arrow_speed: float = 700

var full_charged: bool = false

func _ready() -> void:
	speed = arrow_speed
	area_entered.connect(Callable(self,"_on_area_entered"))
	body_entered.connect(Callable(self,"_on_body_entered"))

func charge_arrow(level: float):
	if level < 2.0:
		$AnimationPlayer.play("default")
	elif level < 3.0:
		$AnimationPlayer.play("charge_1")
	elif level == 3.0:
		$AnimationPlayer.play("charge_2")
		full_charged = true

func _on_area_entered(area: Area2D) -> void:
	if area.name == "Hurtbox":
		if area.get_parent().has_method("take_damage")\
		and area.get_parent().player_id != player_id:
			area.get_parent().take_damage(damage)
			if !full_charged:
				queue_free()
