extends Node2D

@export var fireball_scene: PackedScene

@onready var player: CharacterBody2D
@onready var anim_player: AnimationPlayer
@onready var main_node: Node
@onready var dodge_timer: Timer

var attack_1_length: float = 0.3
var attack_2_length: float = 0.3
var attack_3_length: float = 0.5
var combo_timer = 1.5
var base_speed = 200
var type = "ranged"

var mouse_pos

func _ready() -> void:
	player = get_parent()
	dodge_timer = player.get_node("DodgeCooldownTimer")
	anim_player = $AnimationPlayer
	base_speed = player.speed
	main_node = get_tree().root.get_node("Main")
	
	get_animation_lengths()

func _process(delta: float) -> void:
	pass

@rpc("any_peer","call_local")
func attack(index: float):
	player.speed = 30
	player.can_dodge = false
	player.is_attacking = true
	$ComboTimer.stop()
	$ComboTimer.wait_time = combo_timer
	match index:
		1.0:
			$ComboTimer.start()
			spawn_projectile(player.attack_index)
			use_attack_timer(attack_1_length)
		2.0:
			$ComboTimer.start()
			spawn_projectile(player.attack_index)
			use_attack_timer(attack_2_length)
		3.0:
			spawn_projectile(player.attack_index)
			use_attack_timer(attack_3_length)

func spawn_projectile(index: float):
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
	
	await get_tree().create_timer(spawn_time).timeout
	if index != 3.0:
		var fireball = fireball_scene.instantiate()
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
			
			await get_tree().create_timer(0.2).timeout

func use_attack_timer(time: float):
	$AttackTimer.wait_time = time
	$AttackTimer.start()
	await $AttackTimer.timeout
	player.is_attacking = false
	if player.attack_index == 3.0:
		player.attack_index = 1.0 # Reset after 3rd attack
		$ComboTimer.wait_time = 1.0
		$ComboTimer.start()
	else:
		player.attack_index += 1.0
		player.can_attack = true
	player.speed = base_speed
	if dodge_timer.is_stopped(): player.can_dodge = true

func get_animation_lengths():
	attack_1_length = anim_player.get_animation("attack_right_1").length
	attack_2_length = anim_player.get_animation("attack_right_2").length
	attack_3_length = anim_player.get_animation("attack_right_3").length

func _on_combo_timer_timeout() -> void:
	player.attack_index = 1.0
	player.can_attack = true

func stop_systems():
	$ComboTimer.stop()
	$AttackTimer.stop()
	player.speed = base_speed
