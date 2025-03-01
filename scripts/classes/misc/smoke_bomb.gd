extends Node2D

var player_id = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$SpellHitbox.player_id = player_id
	start_spell()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func start_spell():
	$SpellFX.play("spell1")
	#await get_tree().create_timer(0.3)
	#$SpellHitbox.set_deferred("monitoring",false)
	await $SpellFX.animation_finished
	queue_free()
