extends Node2D

@export var fireball_scene: PackedScene

@onready var player: CharacterBody2D
@onready var anim_player: AnimationPlayer

var release_length: float = 0.2
var ready_length: float = 0.5
var charge_1_length: float = 0.4
var charge_2_length: float = 0.5
var combo_timer = 0.5

func _ready() -> void:
	player = get_parent()
	anim_player = $AnimationPlayer
	
	get_animation_lengths()

func _process(delta: float) -> void:

func attack(index: int):
	player.is_attacking = true
	$ComboTimer.wait_time = combo_timer
	match index:
		1:
			print("Readying")
			await get_tree().create_timer(ready_length).timeout
			spawn_projectile(player.attack_index)
			$ComboTimer.start()
			player.is_attacking = false
			player.attack_index += 1
		2:
			print("Charge 2")
			await get_tree().create_timer(charge_1_length).timeout
			$ComboTimer.start()
			spawn_projectile(player.attack_index)
			player.is_attacking = false
			player.attack_index += 1
		3:
			print("Charge 3")
			spawn_projectile(player.attack_index)
			$ComboTimer.wait_time = charge_2_length
			$ComboTimer.start()

func charge_projectile():
	pass

func spawn_projectile(attack: int):
	var spawn_time = 0.3
	var mouse_pos = player.get_global_mouse_position()
	
	match attack:
		1:
			spawn_time = attack_1_length / 2
			spawn_time += 0.05
		2:
			spawn_time = attack_2_length / 2
			spawn_time += 0.05
		3:
			spawn_time= attack_3_length / 2
			spawn_time += 0.05
	
	if attack != 3:
		var fireball = fireball_scene.instantiate()
		await get_tree().create_timer(spawn_time).timeout
		get_tree().current_scene.add_child(fireball)
		fireball.position = $Marker2D.global_position
		fireball.direction = fireball.position.direction_to(mouse_pos)
		fireball.rotation = fireball.direction.angle()
		fireball.velocity = fireball.direction * fireball.speed
	else:
		# Calculate angle offset
		var start_angle = -60 / 2
		var angle_step = 60 / 2
		
		await get_tree().create_timer(spawn_time).timeout
		for i in range(3):
			var fireball = fireball_scene.instantiate()
			get_tree().current_scene.add_child(fireball)
			
			var angle_offset  = deg_to_rad(start_angle + i * angle_step)
			
			# Set projectile position and direction
			fireball.position = $Marker2D.global_position
			fireball.rotation = angle_offset - PI/2
			fireball.velocity = Vector2(0, -100).rotated(angle_offset)
			
			if fireball:
				fireball.start_follow_timer()

func get_animation_lengths():
	release_length = anim_player.get_animation("release_right").length
	print("Release: " + str(release_length))
	ready_length = anim_player.get_animation("ready_right").length
	print("Ready: " + str(ready_length))
	charge_1_length = anim_player.get_animation("charge_1_right").length
	print("Charge 1: " + str(charge_1_length))
	charge_2_length = anim_player.get_animation("charge_2_right").length
	print("Charge 2: " + str(charge_2_length))

func _on_combo_timer_timeout() -> void:
	player.is_attacking = false
	player.attack_index = 1
	player.can_dodge = true
