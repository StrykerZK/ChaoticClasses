extends Area2D

var player_id = 1
var damage: float = 0
var stun_duration: float = 1

func _on_area_entered(area: Area2D) -> void:
	if area.name == "Hurtbox":
		if area.get_parent().has_method("take_damage")\
		and area.get_parent().player_id != player_id:
			area.get_parent().take_damage(damage)
		
		if area.get_parent().has_method("debuff")\
		and area.get_parent().player_id != player_id:
			area.get_parent().debuff("stun",0,stun_duration)
