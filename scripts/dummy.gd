extends CharacterBody2D

@export var armor: float = 2
@export var player_id = 2

var dps: float = 0
var last_dmg: float = 0
var dmg_reduction = 0

func _ready() -> void:
	dmg_reduction = 1 - (armor /  10)
	$AnimatedSprite2D.play("idle")

func _process(delta: float) -> void:
	$DPS.text = "DPS: " + str(dps)
	$LastDamage.text = "Last Dmg: " + str(last_dmg)

@rpc("any_peer", "call_local")
func take_damage(damage: float):
	last_dmg = damage * dmg_reduction
	$DPSTimer.start()
	dps += last_dmg


func reset_dps():
	dps = 0
