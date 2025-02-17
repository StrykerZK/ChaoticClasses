extends CanvasLayer

var player_1
var player_2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_viewport()
	assign_players()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func game_over(id):
	if id == 1:
		$Label.text = StageManager.player_list[player_2.player_id].player_name + " won!"
	else:
		$Label.text = StageManager.player_list[1].player_name + " won!"
	$Label.add_theme_font_size_override("font_size", 60)
	$Label.add_theme_color_override("font_color",Color.MINT_CREAM)
	$Label.position = $ScreenCenter.global_position - Vector2($Label.size.x / 2, $Label.size.y / 2)
	$Label.show()
	
func assign_players():
	var players = get_tree().get_nodes_in_group("players")
	player_1 = players[0]
	player_2 = players[1]
