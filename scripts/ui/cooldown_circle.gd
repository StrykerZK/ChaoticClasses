extends TextureProgressBar

var on_cooldown: bool = false
var tween: Tween

func _process(delta: float) -> void:
	if on_cooldown:
		if value < max_value:
			value = max_value - $Countdown.time_left

func initiate(current_class: String, number: int):
	texture_under = load("res://art/player/spells/" + current_class + "/spell_icon_" + str(number) + ".png")
	texture_progress = load("res://art/player/spells/" + current_class + "/spell_icon_" + str(number) + ".png")

func start_countdown(time: float):
	max_value = time
	value = 0
	on_cooldown = true
	$Countdown.wait_time = time
	$Countdown.start()

func _on_countdown_timeout() -> void:
	on_cooldown = false
	value = max_value
	shine()

func shine():
	material = load("res://utility/shine_shader_material.tres")
	if tween:
		tween.kill()
	tween = create_tween()
	material.set("shader_parameter/shine_active", true)
	tween.tween_property(material, "shader_parameter/sheen_progress", 1.0, 0.3) # Adjust time
	await tween.finished
	material.set("shader_parameter/shine_active", false) # Reset effect
	material.set("shader_parameter/sheen_progress", 0.0) # Reset position
	material = null
