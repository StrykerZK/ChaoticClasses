extends Control

var player_id

var falloff_ready: bool = false

func _ready() -> void:
	player_id = multiplayer.get_unique_id()
	update_display()

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

func dead():
	$Overlay.texture = load("res://art/ui/main_player_info_alt.png")

func start_game():
	$Overlay.texture = load("res://art/ui/main_player_info.png")
	update_display()
	reset_bars(200)
	display_scores()

func update_display():
	$PlayerName.text = StageManager.player_list[player_id].player_name
	$PlayerClass.text = StageManager.player_list[player_id].class
	$PlayerSprite.texture =\
	load("res://art/player/sprites/"+StageManager.player_list[player_id].class+"_sprite.png")
	$CooldownCircle1.initiate(StageManager.player_list[player_id].class, 1)
	$CooldownCircle2.initiate(StageManager.player_list[player_id].class, 2)

func display_scores():
	var score = StageManager.get_player_score(player_id)
	if score == 0:
		$Scores/Score1.play("start")
		$Scores/Score2.play("start")
		$Scores/Score3.play("start")
	elif score == 1:
		$Scores/Score1.play("full")
		$Scores/Score2.play("empty")
		$Scores/Score3.play("empty")
	elif score == 2:
		$Scores/Score1.play("full")
		$Scores/Score2.play("full")
		$Scores/Score3.play("empty")

func update_scores():
	var score = StageManager.get_player_score(player_id)
	if score == 1:
		$Scores/Score1.play("charging")
		$AnimationPlayer.play("score_1_fill")
	elif score == 2:
		$Scores/Score2.play("charging")
		$AnimationPlayer.play("score_2_fill")
	elif score == 3:
		$Scores/Score3.play("charging")
		$AnimationPlayer.play("score_3_fill")

func reset_bars(value: float):
	$HPBar.value = value
	$FalloffBar.value = value

func queue_spell_cooldown(duration: float, number: int):
	match number:
		1: $CooldownCircle1.start_countdown(duration)
		2: $CooldownCircle2.start_countdown(duration)
