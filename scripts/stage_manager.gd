extends Node

var player_list = {}
var player_count = 0

var p1_id: int
var p2_id: int
var p3_id: int
var p4_id: int

var p1_target: Vector2 = Vector2.ZERO
var p2_target: Vector2 = Vector2.ZERO
var p3_target: Vector2 = Vector2.ZERO
var p4_target: Vector2 = Vector2.ZERO

var p1_stats = []
var p2_stats = []
var p3_stats = []
var p4_stats = []

var p1_score: int = 0
var p2_score: int = 0
var p3_score: int = 0
var p4_score: int = 0

var game_state = ""

func _ready():
	pass

func clear_list():
	player_list.clear()
	player_count = 0
	p1_id = 0
	p2_id = 0
	p3_id = 0
	p4_id = 0

@rpc("any_peer","call_local","reliable")
func set_target(id, target):
	match id:
		p1_id: p1_target = target
		p2_id: p2_target = target
		p3_id: p3_target = target
		p4_id: p4_target = target

func get_target(id) -> Vector2:
	match id:
		p1_id: return p1_target
		p2_id: return p2_target
		p3_id: return p3_target
		p4_id: return p4_target
		_: return Vector2.ZERO

func get_player_name(id) -> Variant:
	var player_name = ""
	for keys in player_list:
		if keys == id:
			player_name = player_list[keys].player_name
			return player_name
	return player_name

func get_player_health(id) -> float:
	var health = 0
	match id:
		p1_id:
			if !p1_stats.is_empty():
				health = p1_stats[0]
		p2_id:
			if !p2_stats.is_empty():
				health = p2_stats[0]
		p3_id:
			if !p3_stats.is_empty():
				health = p3_stats[0]
		p4_id:
			if !p4_stats.is_empty():
				health = p4_stats[0]
	return health

func get_player_score(id) -> int:
	match id:
		p1_id: return p1_score
		p2_id: return p2_score
		p3_id: return p3_score
		p4_id: return p4_score
		_: return 0

func get_player_2_id() -> int: # NOT USED
	var player_id = 1
	for keys in player_list:
		if keys != 1:
			return keys
	return player_id

@rpc("any_peer","call_local")
func set_player_ids():
	if player_list.is_empty():
		p1_id = 0
		p2_id = 0
		p3_id = 0
		p4_id = 0
	else:
		var count = 1
		for keys in player_list:
			match count:
				1:
					p1_id = keys
					p2_id = 0
					p3_id = 0
					p4_id = 0
					count += 1
				2:
					p2_id = keys
					count += 1
				3:
					p3_id = keys
					count += 1
				4:
					p4_id = keys
					count = 1

@rpc("any_peer","call_local")
func update_player_stats(id: int, current_health: float):
	match id:
		p1_id:
			if p1_stats.is_empty():
				p1_stats.append(current_health)
			else:
				p1_stats[0] = current_health
		p2_id:
			if p2_stats.is_empty():
				p2_stats.append(current_health)
			else:
				p2_stats[0] = current_health
		p3_id:
			if p3_stats.is_empty():
				p3_stats.append(current_health)
			else:
				p3_stats[0] = current_health
		p4_id:
			if p4_stats.is_empty():
				p4_stats.append(current_health)
			else:
				p4_stats[0] = current_health

@rpc("any_peer","call_local")
func update_game_state(state: String):
	game_state = state

@rpc("any_peer","call_local")
func update_scores(id):
	match id:
		p1_id: p1_score += 1
		p2_id: p2_score += 1
		p3_id: p3_score += 1
		p4_id: p4_score += 1
	if p1_score == 3 or p2_score == 3 or p3_score == 3 or p4_score == 3:
		game_state = "Game Over"

func reset_game():
	game_state = ""
	reset_stats()
	reset_scores()

func reset_stats():
	p1_stats.clear()
	p2_stats.clear()
	p3_stats.clear()
	p4_stats.clear()

func reset_scores():
	p1_score = 0
	p2_score = 0
	p3_score = 0
	p4_score = 0
