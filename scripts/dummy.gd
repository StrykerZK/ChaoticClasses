extends CharacterBody2D

var dps: float = 0

func _process(delta: float) -> void:
	$DPS.text = "DPS: " + str(dps)

func take_damage(source: Area2D):
	var dmg = StageManager.p1_damage
	$DPSTimer.start()
	$LastDamage.text = "Last Dmg: " + str(dmg)
	dps += dmg

func reset_dps():
	dps = 0
