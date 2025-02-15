extends Node

var player_list = {}
var player_count = 0

var p1_target: Vector2 = Vector2.ZERO
var p2_target: Vector2 = Vector2.ZERO

func _ready():
	pass

@rpc("any_peer","call_local")
func set_target(id, target):
	if id == 1:
		p1_target = target
	else:
		p2_target = target

func get_target(id) -> Vector2:
	if id == 1:
		return p1_target
	else:
		return p2_target

func update_player_stats(id: int, max: float, current: float, damage: float):
	pass
