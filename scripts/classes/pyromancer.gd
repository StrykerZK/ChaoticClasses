extends Node2D

@export var fireball_scene: PackedScene

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

func attack(index: int):
	player.is_attacking = true
	$ComboTimer.wait_time = combo_timer
	match index:
		1:
			print("attack 1")
			$ComboTimer.start()
			spawn_projectile(player.attack_index)
			await get_tree().create_timer(attack_1_length).timeout
			player.is_attacking = false
			player.attack_index += 1
		2:
			print("attack 2")
			$ComboTimer.start()
			spawn_projectile(player.attack_index)
			await get_tree().create_timer(attack_2_length).timeout
			player.is_attacking = false
			player.attack_index += 1
		3:
			player.can_dodge = false
			print("attack 3")
			spawn_projectile(player.attack_index)
			$ComboTimer.wait_time = attack_3_length
			$ComboTimer.start()

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
		
		for i in range(3):
			var fireball = fireball_scene.instantiate()
			get_tree().current_scene.add_child(fireball)
			
			var angle_offset  = deg_to_rad(start_angle + i * angle_step)
			
			# Set projectile position and direction
			fireball.position = global_position
			fireball.rotation = angle_offset - PI/2
			fireball.velocity = Vector2(0, -100).rotated(angle_offset)
			
			if fireball:
				fireball.start_follow_timer()
			

func get_animation_lengths():
	attack_1_length = anim_player.get_animation("attack_right_1").length
	print("Attack 1: " + str(attack_1_length))
	attack_2_length = anim_player.get_animation("attack_right_2").length
	print("Attack 2: " + str(attack_2_length))
	attack_3_length = anim_player.get_animation("attack_right_3").length
	print("Attack 3: " + str(attack_3_length))

func _on_combo_timer_timeout() -> void:
	player.is_attacking = false
	player.attack_index = 1
	player.can_dodge = true
