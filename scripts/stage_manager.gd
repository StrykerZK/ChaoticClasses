extends Node

var p1_max_health: float
var p1_current_health: float
var p1_damage: float
var p1_score: int

var p2_max_health: float
var p2_current_health: float
var p2_damage: float
var p2_score: int

func _ready():
	pass

func update_player_stats(id: int, max: float, current: float, damage: float):
	p1_damage = damage
