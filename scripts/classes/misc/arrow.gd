extends Area2D

@export var speed: float = 300

var direction: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var mouse_pos: Vector2 = Vector2.ZERO

var full_charged: bool = false
var damage: float = 0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	position += velocity * delta

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
		and area.get_parent().player_id != 1:
			area.get_parent().take_damage(damage)
			if !full_charged:
				queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("dummy"):
		if !full_charged:
			queue_free()
	elif body.is_in_group("environment"):
		queue_free()
