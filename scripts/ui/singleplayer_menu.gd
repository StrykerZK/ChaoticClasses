extends Control

@export var singleplayer_game: PackedScene

func _ready() -> void:
	pass

func _on_play_pressed() -> void:
	
	NetworkManager.host_solo()
	send_player_information("Stryker", multiplayer.get_unique_id())
	
	await get_tree().process_frame
	start_game()

func start_game() -> void:
	var game = singleplayer_game.instantiate()
	get_tree().current_scene.hide_main_menu()
	$/root/Main/Game.add_child(game)

func send_player_information(player_name: String, id: int) -> void:
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

func remove_player_information(id: int) -> void:
	StageManager.remove_player_information(id)
