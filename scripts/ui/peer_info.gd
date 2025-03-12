extends Control

var player_id

var falloff_ready: bool = false

func _process(delta: float) -> void:
	update_hp()
	check_falloffbar()

func update_hp():
	$HPBar.value = StageManager.get_player_health(player_id)

func check_falloffbar():
	if $FalloffBar.value > $HPBar.value and falloff_ready:
		$FalloffBar.value -= 5
		if $FalloffBar.value <= $HPBar.value:
			$FalloffBar.value = $HPBar.value
			falloff_ready = false

func start_falloff(value):
	$FalloffTimer.stop()
	falloff_ready = false
	$FalloffTimer.start()

func _on_falloff_timer_timeout() -> void:
	falloff_ready = true

func update_display():
	$PlayerName.text = StageManager.player_list[player_id].player_name
	$PlayerClass.text = StageManager.player_list[player_id].class
	$PlayerSprite.texture =\
	load("res://art/player/sprites/"+StageManager.player_list[player_id].class+"_sprite.png")

func update_score():
	$ScoreBar.value = float(StageManager.get_player_score(player_id))

func reset_display():
	$Overlay.texture = load("res://art/ui/other_player_info.png")

func reset_bars(value: float):
	$HPBar.value = value
	$FalloffBar.value = value

func dead():
	$Overlay.texture = load("res://art/ui/other_player_info_alt.png")
