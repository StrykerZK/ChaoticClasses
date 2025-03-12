extends Node2D

@onready var player: CharacterBody2D
@onready var anim_player: AnimationPlayer

var attack_1_length: float = 0.3
var attack_2_length: float = 0.4
@export var dash_speed: float = 0
var last_dash_speed: float = 0
@export var spell_direction: int
var combo_timer = 1.0
var type = "melee"

func _ready() -> void:
	player = get_parent()
	anim_player = $AnimationPlayer
	get_animation_lengths()

func _process(delta: float) -> void:
	check_property_changes()

@rpc("any_peer","call_local")
func attack(index: float):
	player.is_attacking = true
	$ComboTimer.stop()
	$Hitbox.damage = player.damage
	match index:
		1.0:
			player.dash_duration = attack_1_length - 0.1
			$ComboTimer.start()
			use_attack_timer(attack_1_length)
		2.0:
			player.dash_duration = attack_2_length - 0.1
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

@rpc("any_peer","call_local")
func spell_1():
	player.in_spell_1 = true
	var index = randi_range(0,2)
	$TextFX.frame = index
	$SpellTimer.start()

@rpc("any_peer","call_local")
func spell_2():
	player.in_spell_2 = true
	var index = randi_range(1,20)
	if index == 1:
		$TextFX.frame = 4
	else:
		$TextFX.frame = 3
	$SpellTimer.start()

func _on_spell_timer_timeout():
	player.in_spell_1 = false
	player.spell_1_ready = true
	player.in_spell_2 = false
	player.spell_2_ready = true

func get_animation_lengths():
	attack_1_length = anim_player.get_animation("slap_1_right").length
	attack_2_length = anim_player.get_animation("slap_2_right").length

func _on_combo_timer_timeout() -> void:
	player.attack_index = 1.0
	player.damage = player.base_damage

func stop_systems():
	$ComboTimer.stop()
	$AttackTimer.stop()

func check_property_changes():
	if last_dash_speed != dash_speed:
		player.dash_speed = dash_speed
		player.tween_dash_value()
		last_dash_speed = dash_speed
	else:
		pass

func stop_spells():
	pass
