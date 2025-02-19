extends CanvasLayer

var player_1
var player_2

func _ready() -> void:
	assign_players()

func _process(delta: float) -> void:
	pass

func game_over(id):
	if id == 1:
		$Label.text = str(StageManager.get_player_2_name()) + " won!"
		if is_instance_valid(player_2.get_node("Camera")):
			player_2.get_node("Camera").queue_free()
	else:
		$Label.text = StageManager.player_list[1].player_name + " won!"
		if is_instance_valid(player_1.get_node("Camera")):
			player_1.get_node("Camera").queue_free()
	$Label.add_theme_font_size_override("font_size", 60)
	$Label.add_theme_color_override("font_color",Color.MINT_CREAM)
	$Label.position = $ScreenCenter.global_position - Vector2($Label.size.x / 2, $Label.size.y / 2)
	$Label.show()

func start_game():
	$Player1Info.show()
	$Player2Info.show()

@rpc("any_peer","call_local")
func class_change():
	$Player1Info.update_display()
	$Player2Info.update_display()

func assign_players(): # Not used
	var players = get_tree().get_nodes_in_group("players")
	player_1 = players[0]
	player_2 = players[1]
