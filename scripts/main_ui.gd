extends CanvasLayer

var player_1
var player_2

func _ready() -> void:
	assign_players()
	$Label.hide()
	$FX.hide()

func _process(delta: float) -> void:
	pass

func start_game():
	# Assign player nodes
	assign_players()
	$Player1Info.update_display()
	$Player2Info.update_display()
	$Player1Info.reset_bars(200)
	$Player2Info.reset_bars(200)
	
	# Start animation for countdown
	$AnimationPlayer.play("start_game")
	await $AnimationPlayer.animation_finished
	
	# Play fight text fx
	$FX.show()
	$FX.play("fight")
	await $FX.animation_finished
	$FX.hide()
	
	# Setup player info tabs
	$Player1Info.show()
	$Player1Info.display_scores()
	$Player2Info.show()
	$Player2Info.display_scores()

func game_over(id):
	if id == 1:
		await player_1.tree_exited
		$Label.text = str(StageManager.get_player_2_name()) + " won!"
		$Player2Info.update_scores()
	else:
		await player_2.tree_exited
		$Label.text = StageManager.player_list[1].player_name + " won!"
		$Player1Info.update_scores()
	
	$Label.add_theme_font_size_override("font_size", 60)
	$Label.add_theme_color_override("font_color",Color.CRIMSON)
	$Label.position = $ScreenCenter.global_position - Vector2($Label.size.x / 2, $Label.size.y / 2)
	$Label.show()

func game_end():
	$AnimationPlayer.play("game_end")

@rpc("any_peer","call_local")
func class_change():
	$Player1Info.update_display()
	$Player2Info.update_display()

func assign_players(): # Not used
	var players = get_tree().get_nodes_in_group("players")
	player_1 = players[0]
	player_2 = players[1]
