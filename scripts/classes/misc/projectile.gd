extends Area2D

class_name Projectile

var speed: float = 300
var direction: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var mouse_pos: Vector2 = Vector2.ZERO

var player_id: int = 1
var damage: float


func _process(delta: float) -> void:
	position += velocity * delta

func _on_area_entered(area: Area2D) -> void:
	if area.name == "Hurtbox":
		if area.get_parent().has_method("take_damage")\
		and area.get_parent().player_id != player_id:
			area.get_parent().take_damage.rpc(damage)
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("dummy"):
		queue_free()
	elif body.is_in_group("environment"):
		queue_free()
