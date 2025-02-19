extends Control

var player_id

var falloff_ready: bool = false

func _ready() -> void:
	player_id = StageManager.get_player_2_id()
	update_display.rpc()

func _process(delta: float) -> void:
	if !StageManager.p2_stats.is_empty():
		$HPBar.value = StageManager.p2_stats[0]
	
	
	if $FalloffBar.value != $HPBar.value and falloff_ready:
		$FalloffBar.value -= 1
		if $FalloffBar.value == $HPBar.value:
			falloff_ready = false

func start_falloff(value):
	$FalloffTimer.stop()
	falloff_ready = false
	$FalloffTimer.start()

func _on_falloff_timer_timeout() -> void:
	falloff_ready = true

@rpc("any_peer","call_local")
func update_display():
	$PlayerName.text = StageManager.player_list[player_id].player_name
	$PlayerClass.text = StageManager.player_list[player_id].class
	$PlayerSprite.texture =\
	load("res://art/player/sprites/"+StageManager.player_list[player_id].class+"_sprite.png")
