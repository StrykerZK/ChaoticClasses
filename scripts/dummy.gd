extends CharacterBody2D

@export var armor: float = 2
@export var player_id = 2

var dps: float = 0
var dmg_reduction = 0

func _ready() -> void:
	dmg_reduction = 1 - (armor /  10)

func _process(delta: float) -> void:
	$DPS.text = "DPS: " + str(dps)

func take_damage(damage: float):
	var new_dmg = damage * dmg_reduction
	$DPSTimer.start()
	$LastDamage.text = "Last Dmg: " + str(new_dmg)
	dps += new_dmg


func reset_dps():
	dps = 0
