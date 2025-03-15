extends Area2D

var player_id
var damage = 25
var activated: bool = false

func _ready() -> void:
	$AnimatedSprite2D.play("start")

func _on_animated_sprite_2d_animation_finished() -> void:
	if !activated:
		activated = true
		set_deferred("monitoring",true)
		$AnimatedSprite2D.play("end")
	else:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.name == "Hurtbox":
		if area.get_parent().has_method("take_damage")\
		and area.get_parent().player_id != player_id:
			area.get_parent().take_damage(damage)
