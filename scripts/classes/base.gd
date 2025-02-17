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

func attack(index: float):
	$ComboTimer.stop()
	player.is_attacking = true
	$Hitbox.damage = player.damage
	match index:
		1.0:
			$ComboTimer.start()
			await get_tree().create_timer(attack_1_length + 0.01).timeout
			player.is_attacking = false
			player.attack_index += 1.0
		2.0:
			$ComboTimer.start()
			await get_tree().create_timer(attack_2_length + 0.01).timeout
			player.is_attacking = false
			player.attack_index = 1.0
			player.damage += player.base_damage

func get_animation_lengths():
	attack_1_length = anim_player.get_animation("slap_1_right").length
	attack_2_length = anim_player.get_animation("slap_2_right").length

func _on_combo_timer_timeout() -> void:
	player.attack_index = 1.0
	player.damage = player.base_damage
