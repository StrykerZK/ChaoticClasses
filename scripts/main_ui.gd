extends CanvasLayer

var player_1: CharacterBody2D
var player_2: CharacterBody2D
var player_3: CharacterBody2D
var player_4: CharacterBody2D

var is_paused: bool = false

func _ready() -> void:
	$Label.hide()
	$FX.hide()

func _process(delta: float) -> void:
	pass

func start_game():
	# Assign player nodes
	assign_players()
	$MainPlayerInfo.start_game()
	$PeerInfoPanel.start_game()
	
	# Start animation for countdown
	$AnimationPlayer.play("start_game")
	await $AnimationPlayer.animation_finished
	
	# Play fight text fx
	$FX.show()
	$FX.play("fight")
	await $FX.animation_finished
	$FX.hide()
	
	# Setup player info tabs
	
	$MainPlayerInfo.show()
	$PeerInfoPanel.show()

@rpc("any_peer","call_local")
func player_dead(id):
	if id == multiplayer.get_unique_id():
		$MainPlayerInfo.dead()
	else:
		$PeerInfoPanel.player_dead(id)

@rpc("any_peer","call_local","reliable")
func match_over(id):
	$Label.text = StageManager.get_player_name(id) + " won!"
	$Label.add_theme_font_size_override("font_size", 60)
	$Label.add_theme_color_override("font_color",Color.CRIMSON)
	$Label.position = $ScreenCenter.global_position - Vector2($Label.size.x / 2, $Label.size.y / 2)
	$Label.show()
	
	if id == multiplayer.get_unique_id():
		$MainPlayerInfo.update_scores()
	else:
		$PeerInfoPanel.update_scores(id)

func game_end():
	$AnimationPlayer.play("game_end")

@rpc("any_peer","call_local")
func class_change():
	$MainPlayerInfo.update_display()
	$PeerInfoPanel.update_displays()

@rpc("any_peer","call_local")
func assign_players():
	for player in get_tree().get_nodes_in_group("players"):
		for i in StageManager.player_list:
			if player.name.to_int() != i: continue
			match StageManager.player_list[i].number:
				1: player_1 = player
				2: player_2 = player
				3: player_3 = player
				4: player_4 = player

func toggle_pause():
	is_paused = !is_paused
	if is_paused:
		$PauseMenu.show()
	else:
		$PauseMenu.hide()

func _on_base_pressed() -> void:
	Callable($/root/Main/MultiplayerGame/MultiplayerManager,"dev_class_change").call("base")
	$DevButtons/Base.release_focus()

func _on_hero_pressed() -> void:
	Callable($/root/Main/MultiplayerGame/MultiplayerManager,"dev_class_change").call("hero")
	$DevButtons/Hero.release_focus()

func _on_demon_pressed() -> void:
	Callable($/root/Main/MultiplayerGame/MultiplayerManager,"dev_class_change").call("demon")
	$DevButtons/Demon.release_focus()

func _on_pyro_pressed() -> void:
	Callable($/root/Main/MultiplayerGame/MultiplayerManager,"dev_class_change").call("pyromancer")
	$DevButtons/Pyro.release_focus()

func _on_archer_pressed() -> void:
	Callable($/root/Main/MultiplayerGame/MultiplayerManager,"dev_class_change").call("archer")
	$DevButtons/Archer.release_focus()

func _on_gladiator_pressed() -> void:
	Callable($/root/Main/MultiplayerGame/MultiplayerManager,"dev_class_change").call("gladiator")
	$DevButtons/Gladiator.release_focus()

func _on_necro_pressed() -> void:
	Callable($/root/Main/MultiplayerGame/MultiplayerManager,"dev_class_change").call("necromancer")
	$DevButtons/Necro.release_focus()
