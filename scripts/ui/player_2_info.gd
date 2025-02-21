extends Control

var player_id

var falloff_ready: bool = false

func _ready() -> void:
	player_id = StageManager.get_player_2_id()
	update_display()

func _process(delta: float) -> void:
	check_hp()
	check_falloffbar()

func check_hp():
	if !StageManager.p2_stats.is_empty():
		$HPBar.value = StageManager.p2_stats[0]

func check_falloffbar():
	if $FalloffBar.value > $HPBar.value and falloff_ready:
		$FalloffBar.value -= 1
		if $FalloffBar.value == $HPBar.value:
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

func display_scores():
	if StageManager.p2_score == 0:
		$Scores/Score1.play("start")
		$Scores/Score2.play("start")
		$Scores/Score3.play("start")
	elif StageManager.p2_score == 1:
		$Scores/Score1.play("full")
		$Scores/Score2.play("empty")
		$Scores/Score3.play("empty")
	elif StageManager.p2_score == 2:
		$Scores/Score1.play("full")
		$Scores/Score2.play("full")
		$Scores/Score3.play("empty")

func update_scores():
	if StageManager.p2_score == 1:
		$Scores/Score1.play("charging")
		$AnimationPlayer.play("score_1_fill")
	elif StageManager.p2_score == 2:
		$Scores/Score2.play("charging")
		$AnimationPlayer.play("score_2_fill")
	elif StageManager.p2_score == 3:
		$Scores/Score3.play("charging")
		$AnimationPlayer.play("score_3_fill")

func reset_bars(value: float):
	$HPBar.value = value
	$FalloffBar.value = value
