extends Node2D

var player_id = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$SpellHitbox.damage = 25
	$SpellHitbox.player_id = player_id
	start_spell()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func start_spell():
	$SpellFX.show()
	$SpellFX.play("spell2start")
	$SpellHitbox.monitoring = true
	await $SpellFX.animation_finished
	$SpellFX.play("spell2loop")
	$SpellTimer.start()

func _on_spell_timer_timeout() -> void:
	$SpellFX.play("spell2end")
	await $SpellFX.animation_finished
	$SpellHitbox.monitoring = false
	$SpellFX.stop()
	queue_free()
