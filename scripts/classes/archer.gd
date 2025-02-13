extends Node2D

@export var arrow_scene: PackedScene

@onready var player: CharacterBody2D
@onready var anim_player: AnimationPlayer
@onready var anim_tree: AnimationTree

var release_length: float = 0.2
var ready_length: float = 0.5
var charge_1_length: float = 0.4
var charge_2_length: float = 0.5
var charge_1_time = 1.0
var charge_2_time = 1.5
var can_shoot = false
var early_shot = false

func _ready() -> void:
	player = get_parent()
	anim_player = $AnimationPlayer
	anim_tree = $AnimationTree
	
	get_animation_lengths()

func _process(delta: float) -> void:
	if !player.is_paused and !player.is_dodging:
		handle_input()
	

func handle_input():
	if player.is_attacking:
		if Input.is_action_just_released("attack"):
			if can_shoot:
				spawn_projectile(player.attack_index)
			else:
				early_shot = true

func attack(index: float):
	player.can_dodge = false
	if !player.is_dodging:
		player.is_attacking = true
		$ChargeTimer.wait_time = charge_1_time - charge_1_length
		match index:
			1.0:
				print("Readying")
				await get_tree().create_timer(ready_length).timeout
				if early_shot == true:
					early_shot = false
					spawn_projectile(player.attack_index)
				else:
					can_shoot = true
					print("Charging!")
					$ChargeTimer.start()

func charge_projectile():
	match player.attack_index:
		1.0:
			if player.is_attacking:
				$ChargeTimer.wait_time = charge_2_time - charge_2_length
				player.attack_index += 0.5
			await get_tree().create_timer(charge_1_length).timeout
			if player.is_attacking:
				player.attack_index += 0.5
				player.damage = player.base_damage * 2
				$ChargeTimer.start()
		2.0:
			if player.is_attacking:
				player.attack_index += 0.5
			await get_tree().create_timer(charge_2_length).timeout
			if player.is_attacking:
				player.attack_index += 0.5
				player.damage = player.base_damage * 4

func spawn_projectile(index: float):
	
	$ChargeTimer.stop()
	
	var mouse_pos = player.get_global_mouse_position()

	var arrow = arrow_scene.instantiate()
	get_tree().current_scene.add_child(arrow)
	arrow.position = $Marker2D.global_position
	arrow.direction = arrow.position.direction_to(mouse_pos)
	arrow.rotation = arrow.direction.angle()
	arrow.velocity = arrow.direction * arrow.speed
	arrow.charge_arrow(index)
	
	can_shoot = false
	player.attack_index = 0.0
	await get_tree().create_timer(release_length + 0.2).timeout
	player.is_attacking = false
	player.attack_index = 1.0
	player.can_dodge = true
	early_shot = false
	
	# First arrow always calls previous arrow's damage


func get_animation_lengths():
	release_length = anim_player.get_animation("release_right").length
	print("Release: " + str(release_length))
	ready_length = anim_player.get_animation("ready_right").length
	print("Ready: " + str(ready_length))
	charge_1_length = anim_player.get_animation("charge_1_right").length
	print("Charge 1: " + str(charge_1_length))
	charge_2_length = anim_player.get_animation("charge_2_right").length
	print("Charge 2: " + str(charge_2_length))
