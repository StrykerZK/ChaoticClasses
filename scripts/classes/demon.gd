extends Node2D

@onready var player: CharacterBody2D
@onready var anim_player: AnimationPlayer

var attack_1_length: float = 0.3
var attack_2_length: float = 0.3
var attack_3_length: float = 0.5
var combo_timer = 1.5
var type = "melee"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_parent()
	anim_player = $AnimationPlayer
	get_animation_lengths()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

@rpc("any_peer","call_local")
func attack(index: float):
	player.is_attacking = true
	$ComboTimer.stop()
	$ComboTimer.wait_time = combo_timer
	$Hitbox.damage = player.damage
	match index:
		1.0:
			$ComboTimer.start()
			use_attack_timer(attack_1_length)
		2.0:
			$ComboTimer.start()
			use_attack_timer(attack_2_length)
		3.0:
			player.damage = player.base_damage * 2
			$Hitbox.damage = player.damage
			use_attack_timer(attack_3_length)

func use_attack_timer(time: float):
	$AttackTimer.wait_time = time
	$AttackTimer.start()
	await $AttackTimer.timeout
	player.is_attacking = false
	if player.attack_index == 3:
		player.attack_index = 1 # Reset after 3rd attack
		$ComboTimer.wait_time =  1
		$ComboTimer.start()
	else:
		player.attack_index += 1.0
		player.can_attack = true

func get_animation_lengths():
	attack_1_length = anim_player.get_animation("attack_right_1").length
	attack_2_length = anim_player.get_animation("attack_right_2").length
	attack_3_length = anim_player.get_animation("attack_right_3").length

func _on_combo_timer_timeout() -> void:
	player.attack_index = 1.0
	player.damage = player.base_damage
	player.can_attack = true

func stop_systems():
	$ComboTimer.stop()
	$AttackTimer.stop()
