extends Area2D

class_name Hitbox

var player_id: int = 1
var damage: float
var deflection: bool = true

func _on_area_entered(area: Area2D) -> void:
	if area.name == "Hurtbox":
		if area.get_parent().has_method("take_damage")\
		and area.get_parent().player_id != player_id:
			area.get_parent().take_damage.rpc(damage)
	
	
	if area.is_in_group("projectiles"):
		if deflection:
			area.velocity = -area.velocity
			if is_instance_valid(area.get_node("Sprite2D")):
				area.get_node("Sprite2D").flip_h = true
				area.get_node("Sprite2D").flip_v = true
			elif is_instance_valid(area.get_node("AnimatedSprite2D")):
				area.get_node("AnimatedSprite2D").flip_h = true
				area.get_node("AnimatedSprite2D").flip_v = true
		else:
			pass
	

func _on_body_entered(body: Node2D) -> void:
	pass
