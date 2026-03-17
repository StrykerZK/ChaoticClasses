extends Node

var player_list = {}
var player_count = 0

var game_state = ""

func _ready():
	pass

func clear_list():
	player_list.clear()
	player_count = 0

@rpc("any_peer","call_local","reliable")
func set_target(id, target):
	if player_list.has(id):
		player_list[id].target = target
	else:
		print("Player not found for target!")

func get_target(id) -> Vector2:
	if player_list.has(id):
		return player_list[id].target
	else:
		return Vector2.ZERO # Not found

func get_player_number(id) -> int:
	if player_list.has(id):
		return player_list[id].number
	else:
		return 0

func get_player_name(id) -> Variant:
	if player_list.has(id):
		return player_list[id].player_name
	else:
		return "" # Not found

func get_all_player_names() -> Array:
	var names = []
	for i in player_list:
		names.append(player_list[i].player_name)
	return names

func get_player_health(id) -> float:
	if player_list.has(id):
		return player_list[id].health
	else:
		return 0 # Not found

func get_player_score(id) -> int:
	if player_list.has(id):
		return player_list[id].score
	else:
		return 0 # Not found

@rpc("any_peer","call_local")
func set_player_numbers():
	var number: int = 1
	for i in player_list:
		player_list[i].number = number
		number += 1

@rpc("any_peer","call_local")
func update_player_health(id: int, current_health: float):
	if player_list.has(id):
		player_list[id].health = current_health
	else:
		print("Player not found for health!")

@rpc("any_peer","call_local")
func update_game_state(state: String):
	game_state = state

@rpc("any_peer","call_local")
func update_scores(id):
	if player_list.has(id):
		player_list[id].score += 1
		if player_list[id].score == 3:
			update_game_state("Game Over")

func remove_player_information(id):
	if player_list.has(id):
		player_list.erase(id)
	player_count = player_list.size()
	set_player_numbers()

func reset_game():
	game_state = ""
	reset_stats()
	reset_scores()

func reset_stats():
	for i in player_list:
		player_list[i].health = 200.0

func reset_scores():
	for i in player_list:
		player_list[i].score = 0
