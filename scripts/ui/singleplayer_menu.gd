extends Control

@export var singleplayer_game: PackedScene

func _on_play_pressed() -> void:
	NetworkManager.host_solo()

func send_player_information(player_name, id):
	if !StageManager.player_list.has(id):
		StageManager.player_list[id] = {
			"player_name": player_name,
			"number": StageManager.player_list.size() + 1,
			"id": id,
			"class": "base",
			"score": 0,
			"health": 200.0,
			"target": Vector2.ZERO
		}
		StageManager.player_count += 1

func remove_player_information(id):
	StageManager.remove_player_information(id)
