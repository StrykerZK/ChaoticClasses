extends Node2D

@export var fireball_scene: PackedScene

@onready var player: CharacterBody2D
@onready var anim_player: AnimationPlayer
@onready var main_node: Node

var attack_1_length: float = 0.3
var attack_2_length: float = 0.3
var attack_3_length: float = 0.5
var combo_timer = 1.5
var type = "ranged"

var mouse_pos

func _ready() -> void:
	player = get_parent()
	anim_player = $AnimationPlayer
	main_node = get_tree().root.get_node("Main")
	
	get_animation_lengths()
	

func _process(delta: float) -> void:
	pass

func attack(index: float):
	player.is_attacking = true
	$ComboTimer.stop()
	$ComboTimer.wait_time = combo_timer
	match index:
		1.0:
			$ComboTimer.start()
			spawn_projectile.rpc(player.attack_index)
			await get_tree().create_timer(attack_1_length).timeout
			player.is_attacking = false
			player.attack_index += 1.0
		2.0:
			$ComboTimer.start()
			spawn_projectile.rpc(player.attack_index)
			await get_tree().create_timer(attack_2_length).timeout
			player.is_attacking = false
			player.attack_index += 1.0
		3.0:
			player.can_dodge = false
			spawn_projectile.rpc(player.attack_index)
			$ComboTimer.wait_time = attack_3_length + 0.2
			$ComboTimer.start()

@rpc("any_peer","call_local")
func spawn_projectile(index: float):
	
	#if is_multiplayer_authority():
	#	mouse_pos = player.mouse_pos
	#else:
	if player.player_id == 1:
		mouse_pos = StageManager.p1_target
	elif player.player_id != 1:
		mouse_pos = StageManager.p2_target
	
	var spawn_time = 0.3
	match index:
		1.0:
			spawn_time = attack_1_length / 2
			spawn_time += 0.05
		2.0:
			spawn_time = attack_2_length / 2
			spawn_time += 0.05
		3.0:
			spawn_time= attack_3_length / 2
			spawn_time += 0.05
	
	if index != 3.0:
		var fireball = fireball_scene.instantiate()
		await get_tree().create_timer(spawn_time).timeout
		main_node.add_child(fireball)
		fireball.position = $Marker2D.global_position
		fireball.direction = fireball.position.direction_to(mouse_pos)
		fireball.rotation = fireball.direction.angle()
		fireball.velocity = fireball.direction * fireball.speed
		fireball.damage = player.damage
		fireball.player_id = player.player_id
	else:
		# Calculate angle offset
		var start_angle = -60 / 2
		var angle_step = 60 / 2
		
		await get_tree().create_timer(spawn_time).timeout
		for i in range(3):
			var fireball = fireball_scene.instantiate()
			main_node.add_child(fireball)
			
			var angle_offset  = deg_to_rad(start_angle + i * angle_step)
			
			# Set projectile position and direction
			fireball.position = $Marker2D.global_position
			fireball.mouse_pos = mouse_pos
			fireball.rotation = angle_offset - PI/2
			fireball.velocity = Vector2(0, -100).rotated(angle_offset)
			fireball.damage = player.damage
			fireball.player_id = player.player_id
			
			if fireball:
				fireball.start_follow_timer()

func get_animation_lengths():
	attack_1_length = anim_player.get_animation("attack_right_1").length
	attack_2_length = anim_player.get_animation("attack_right_2").length
	attack_3_length = anim_player.get_animation("attack_right_3").length

func _on_combo_timer_timeout() -> void:
	player.is_attacking = false
	player.attack_index = 1.0
	player.can_dodge = true
