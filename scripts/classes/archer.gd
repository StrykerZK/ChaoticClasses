extends Node2D

@export var arrow_scene: PackedScene

@onready var player: CharacterBody2D
@onready var anim_player: AnimationPlayer
@onready var anim_tree: AnimationTree
@onready var main_node: Node

var release_length: float = 0.2
var ready_length: float = 0.5
var charge_1_length: float = 0.4
var charge_2_length: float = 0.5
var charge_1_time = 1.0
var charge_2_time = 1.5
var can_shoot = false
var early_shot = false
var current_speed = 150
var type = "ranged"

var mouse_pos

func _ready() -> void:
	player = get_parent()
	anim_player = $AnimationPlayer
	anim_tree = $AnimationTree
	current_speed = player.speed
	main_node = get_tree().root.get_node("Main")
	
	get_animation_lengths()
	
	mouse_pos = get_global_mouse_position()

func _process(delta: float) -> void:
	if !player.is_paused and !player.is_dodging:
		handle_input()

func handle_input():
	if player.is_attacking:
		if Input.is_action_just_released("attack"):
			mouse_pos = get_global_mouse_position()
			StageManager.set_target.rpc(player.player_id,mouse_pos)
			if can_shoot:
				spawn_projectile.rpc(player.attack_index)
			else:
				early_shot = true

@rpc("any_peer","call_local")
func attack(index: float):
	player.speed = 30
	player.can_dodge = false
	can_shoot = false
	if !player.is_dodging:
		player.is_attacking = true
		$ChargeTimer.wait_time = charge_1_time - charge_1_length
		match index:
			1.0:
				await get_tree().create_timer(ready_length).timeout
				if early_shot == true:
					early_shot = false
					spawn_projectile.rpc(player.attack_index)
				else:
					can_shoot = true
					$ChargeTimer.start()

@rpc("any_peer","call_local")
func charge_projectile():
	match player.attack_index:
		1.0:
			if player.is_attacking:
				$ChargeTimer.wait_time = charge_2_time - charge_2_length
				player.attack_index += 0.5
				$ChargeAnimTimer.wait_time = charge_1_length
				$ChargeAnimTimer.start()
			if player.is_attacking:
				player.attack_index += 0.5
				player.damage = player.base_damage * 2
				$ChargeTimer.start()
		2.0:
			if player.is_attacking:
				player.attack_index += 0.5
			$ChargeAnimTimer.wait_time = charge_2_length
			$ChargeAnimTimer.start()
			if player.is_attacking:
				player.attack_index += 0.5
				player.damage = player.base_damage * 4

@rpc("any_peer","call_local")
func spawn_projectile(index: float):
	$ChargeTimer.stop()
	$ChargeAnimTimer.stop()
	player.speed = 0
	if player.attack_index == 1.5 or player.attack_index == 2.5:
		player.attack_index -= 0.5
	
	if player.player_id == 1:
		mouse_pos = StageManager.p1_target
	else:
		mouse_pos = StageManager.p2_target
	
	var arrow = arrow_scene.instantiate()
	main_node.add_child(arrow)
	arrow.position = $Marker2D.global_position
	arrow.direction = arrow.position.direction_to(mouse_pos)
	arrow.rotation = arrow.direction.angle()
	arrow.velocity = arrow.direction * arrow.speed
	arrow.damage = player.damage
	arrow.player_id = player.player_id
	arrow.charge_arrow(index)
	
	can_shoot = false
	player.attack_index = 0.0
	await get_tree().create_timer(release_length + 0.2).timeout
	player.is_attacking = false
	player.attack_index = 1.0
	player.can_dodge = true
	player.damage = player.base_damage
	early_shot = false
	player.speed = current_speed


func get_animation_lengths():
	release_length = anim_player.get_animation("release_right").length
	ready_length = anim_player.get_animation("ready_right").length
	charge_1_length = anim_player.get_animation("charge_1_right").length
	charge_2_length = anim_player.get_animation("charge_2_right").length
