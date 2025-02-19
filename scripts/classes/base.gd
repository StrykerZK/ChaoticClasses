extends Node2D

@onready var player: CharacterBody2D
@onready var anim_player: AnimationPlayer

var attack_1_length: float = 0.3
var attack_2_length: float = 0.4
var combo_timer = 1.0
var type = "melee"

func _ready() -> void:
	player = get_parent()
	anim_player = $AnimationPlayer
	get_animation_lengths()

func _process(delta: float) -> void:
	pass

@rpc("any_peer","call_local")
func attack(index: float):
	player.is_attacking = true
	$ComboTimer.stop()
	$Hitbox.damage = player.damage
	match index:
		1.0:
			$ComboTimer.start()
			use_attack_timer(attack_1_length)
		2.0:
			$ComboTimer.start()
			player.damage += player.base_damage
			use_attack_timer(attack_2_length)

func use_attack_timer(time: float):
	$AttackTimer.wait_time = time
	$AttackTimer.start()
	await $AttackTimer.timeout
	player.is_attacking = false
	if player.attack_index == 2.0:
		player.attack_index = 1.0 # Reset after 2nd attack
	else:
		player.attack_index += 1.0
	player.can_attack = true

func get_animation_lengths():
	attack_1_length = anim_player.get_animation("slap_1_right").length
	attack_2_length = anim_player.get_animation("slap_2_right").length

func _on_combo_timer_timeout() -> void:
	player.attack_index = 1.0
	player.damage = player.base_damage

func stop_systems():
	$ComboTimer.stop()
	$AttackTimer.stop()
