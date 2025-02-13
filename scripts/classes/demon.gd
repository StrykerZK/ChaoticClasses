extends Node2D

@onready var player: CharacterBody2D
@onready var anim_player: AnimationPlayer

var attack_1_length: float = 0.3
var attack_2_length: float = 0.3
var attack_3_length: float = 0.5
var combo_timer = 1.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_parent()
	anim_player = $AnimationPlayer
	get_animation_lengths()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func attack(index: float):
	player.is_attacking = true
	$ComboTimer.wait_time = combo_timer
	match index:
		1.0:
			print("attack 1")
			$ComboTimer.start()
			await get_tree().create_timer(attack_1_length).timeout
			player.is_attacking = false
			player.attack_index += 1.0
		2.0:
			print("attack 2")
			$ComboTimer.start()
			await get_tree().create_timer(attack_2_length).timeout
			player.is_attacking = false
			player.attack_index += 1.0
		3.0:
			player.damage = player.base_damage * 2
			player.can_dodge = false
			print("attack 3")
			$ComboTimer.wait_time = attack_3_length
			$ComboTimer.start()

func get_animation_lengths():
	attack_1_length = anim_player.get_animation("attack_right_1").length
	print("Attack 1: " + str(attack_1_length))
	attack_2_length = anim_player.get_animation("attack_right_2").length
	print("Attack 2: " + str(attack_2_length))
	attack_3_length = anim_player.get_animation("attack_right_3").length
	print("Attack 3: " + str(attack_3_length))

func _on_combo_timer_timeout() -> void:
	player.is_attacking = false
	player.attack_index = 1.0
	player.damage = player.base_damage
	player.can_dodge = true
