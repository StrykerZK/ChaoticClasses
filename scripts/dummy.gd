extends CharacterBody2D

@export var armor: float = 2

var dps: float = 0
var dmg_reduction = 0

func _ready() -> void:
	dmg_reduction = 1 - (armor /  10)

func _process(delta: float) -> void:
	$DPS.text = "DPS: " + str(dps)

func take_damage(source: Area2D):
	print("area entered")
	var dmg = StageManager.p1_damage
	var new_dmg = dmg * dmg_reduction
	$DPSTimer.start()
	$LastDamage.text = "Last Dmg: " + str(new_dmg)
	dps += new_dmg
	
	if source.is_in_group("projectiles"):
		source.queue_free()

func reset_dps():
	dps = 0
