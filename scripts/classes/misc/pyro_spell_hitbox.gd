extends Area2D

var damage: float = 75.0
var player_id: int = 1

func _ready() -> void:
	player_id = get_parent().get_parent().player_id

func _on_area_entered(area: Area2D) -> void:
	if area.name == "Hurtbox":
		if area.get_parent().has_method("take_damage")\
		and area.get_parent().player_id != player_id:
			area.get_parent().take_damage(damage)
