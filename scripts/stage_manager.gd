extends Node

var player_list = {}
var player_count = 0

var p1_target: Vector2 = Vector2.ZERO
var p2_target: Vector2 = Vector2.ZERO

var game_state = ""

var p1_stats = []
var p2_stats = []

var p1_score: int = 0
var p2_score: int = 0

func _ready():
	pass

func clear_list():
	player_list.clear()
	player_count = 0

@rpc("any_peer","call_local","reliable")
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

func get_player_2_name() -> Variant:
	var player_name = ""
	for keys in player_list:
		if keys != 1:
			player_name = player_list[keys].player_name
			return player_name
	return player_name

func get_player_2_id() -> int:
	var player_id = 1
	for keys in player_list:
		if keys != 1:
			return keys
	return player_id

@rpc("any_peer","call_local")
func update_player_stats(id: int, current_health: float):
	if id == 1:
		if p1_stats.is_empty():
			p1_stats.append(current_health)
		else:
			p1_stats[0] = current_health
	else:
		if p2_stats.is_empty():
			p2_stats.append(current_health)
		else:
			p2_stats[0] = current_health

@rpc("any_peer","call_local")
func update_game_state(state: String):
	game_state = state

func game_over(id):
	if id == 1:
		p2_score += 1
	else:
		p1_score += 1

func reset_game():
	game_state = ""
	p1_stats.clear()
	p1_score = 0
	p2_stats.clear()
	p2_score = 0
