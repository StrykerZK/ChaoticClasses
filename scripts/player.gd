extends CharacterBody2D

@export var current_class = "Base"
@export var current_type = "melee"
@export var player_id: int = 1

signal dead(int)

var max_health: float = 200
var current_health: float
var armor: float = 0
var base_damage: float = 5
var damage: float = base_damage
var speed: float = 150.0
var dodge_speed_mult = 4
var dodge_duration = 0.6
var dodge_cooldown = 1.5 
var dodge_speed = 0.0

@onready var anim_tree: AnimationTree
@onready var anim_player: AnimationPlayer
@onready var class_synchronizer: MultiplayerSynchronizer
@onready var player_manager: Node
@onready var HP_bar: ProgressBar
@onready var hitbox: Area2D

var direction: Vector2 = Vector2.ZERO
var last_input_direction: Vector2 = Vector2(1,0)
var changing_class = false
var is_paused = false

# Variables for dodging
var is_dodging = false
var can_dodge = true
var dodge_count = 1
var temp_count = 1

# Variables for attacking
var is_attacking = false
var attack_index: float = 1.0
var attack_method = Callable(self, "attack")
var mouse_pos: Vector2 = Vector2.ZERO
var local_mouse_pos: Vector2 = Vector2.ZERO
var last_mouse_pos: Vector2 = Vector2.ZERO
var attack_1_length: float = 0.3
var attack_2_length: float = 0.4
var combo_timer = 1.0

func _enter_tree() -> void:
	ready.connect(Callable($/root/Main/GameManager,"_on_players_connected"))
	dead.connect(Callable($/root/Main/GameManager,"game_over"))
	dead.connect(Callable($/root/Main/UI,"game_over"))
	set_multiplayer_authority(int(str(name)))

func _ready() -> void:
	player_manager = get_node("/root/Main/PlayerManager")
	player_id = int(str(name))
	
	current_class = get_child(0).name
	class_synchronizer = $ClassSynchronizer
	$PlayerSynchronizer.root_path = get_path()
	
	HP_bar = get_node("UI/HPBar")
	HP_bar.max_value = max_health
	
	hitbox = get_node("Base/Hitbox")
	hitbox.player_id = player_id
	
	initialize_class_children()
	
	$Base/ComboTimer.wait_time = combo_timer
	$DodgeTimer.wait_time = dodge_duration
	dodge_speed = speed * dodge_speed_mult
	current_health = max_health
	temp_count = dodge_count
	# Set up camera for each
	if is_multiplayer_authority():
		create_camera()

func _process(delta: float) -> void:
	if !is_paused:
		if is_multiplayer_authority():
			mouse_pos = get_global_mouse_position()
			local_mouse_pos = get_local_mouse_position()
			handle_input() # Input data
			
			move_and_slide() # Character movement
			
			if is_instance_valid(anim_tree):
				update_animation_parameters() # Update AnimationTree
				
			$Label.position = global_position
		#StageManager.update_player_stats(player_id, max_health, current_health, damage)

func handle_input():
	if current_class != "archer": # If not archer, don't move while attacking
		if !is_dodging and !is_attacking:
			direction = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
		
		if direction and !is_attacking:
			last_input_direction = direction
			if is_dodging:
				velocity = last_input_direction * dodge_speed
			else:
				velocity = direction * speed
		else:
			if is_dodging:
				velocity = last_input_direction * dodge_speed
			else:
				velocity = Vector2.ZERO
	else: # If archer, move while attacking
		if !is_dodging:
			direction = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
		
		if direction:
			last_input_direction = direction
			if is_dodging:
				velocity = last_input_direction * dodge_speed
			else:
				velocity = direction * speed
		else:
			if is_dodging:
				velocity = last_input_direction * dodge_speed
			else:
				velocity = Vector2.ZERO
	
	
	if Input.is_action_just_pressed("dodge"):
		if can_dodge:
			start_dodge()
	
	if Input.is_action_just_pressed("attack"):
		if !is_attacking and !is_dodging:
			StageManager.set_target.rpc(player_id,mouse_pos)
			last_mouse_pos = local_mouse_pos
			#anim_tree["parameters/attack/blend_position"] = Vector2(mouse_pos.x, attack_index)
			if current_class == "Base":
				attack(attack_index)
			else:
				attack_method.call(attack_index)

func attack(index: float):
	$Base/ComboTimer.stop()
	is_attacking = true
	hitbox.damage = damage
	match index:
		1.0:
			$Base/ComboTimer.start()
			await get_tree().create_timer(attack_1_length + 0.01).timeout
			is_attacking = false
			attack_index += 1.0
		2.0:
			$Base/ComboTimer.start()
			await get_tree().create_timer(attack_2_length + 0.01).timeout
			is_attacking = false
			attack_index = 1.0
			damage += base_damage

func _on_combo_timer_timeout() -> void:
	attack_index = 1.0
	damage = base_damage

func start_dodge():
	is_dodging = true
	can_dodge = false
	
	activate_i_frame(dodge_duration)
	
	dodge_speed = speed * dodge_speed_mult
	
	# Tween the dodge speed to 0 smoothly
	var tween = get_tree().create_tween()
	tween.tween_property(self, "dodge_speed", 0.0, dodge_duration)\
	.set_trans(Tween.TRANS_QUAD)\
	.set_ease(Tween.EASE_OUT)
	
	$DodgeTimer.wait_time = dodge_duration
	$DodgeTimer.start()

func end_dodge():
	is_dodging = false
	if temp_count > 1:
		can_dodge = true
		temp_count -= 1
		$DodgeResetTimer.stop()
		$DodgeResetTimer.start()
	elif temp_count == 1:
		$DodgeResetTimer.stop()
		dodge_on_cooldown()

func dodge_on_cooldown():
	can_dodge = false
	await get_tree().create_timer(dodge_cooldown).timeout
	while is_attacking:
		await get_tree().create_timer(0.1).timeout # Wait for attack to finish
	can_dodge = true
	temp_count = dodge_count

func activate_i_frame(value: float):
	$Hurtbox/HurtboxCollision.disabled = true
	$IFrameTimer.start(value)
	await $IFrameTimer.timeout
	$Hurtbox/HurtboxCollision.disabled = false

func update_animation_parameters():
	if !is_dodging and !is_attacking:
		anim_tree.set("parameters/conditions/idle", velocity == Vector2.ZERO)
		anim_tree.set("parameters/conditions/is_running", velocity != Vector2.ZERO)
	else:
		anim_tree.set("parameters/conditions/idle", false)
		anim_tree.set("parameters/conditions/is_running", false)
	
	anim_tree.set("parameters/conditions/is_dodging", is_dodging)
	anim_tree.set("parameters/conditions/is_attacking", is_attacking)
	
	if current_class == "archer":
		anim_tree["parameters/attack/blend_position"] = Vector2(local_mouse_pos.x, attack_index)
	else:
		anim_tree["parameters/attack/blend_position"] = Vector2(last_mouse_pos.x, attack_index)
	
	
	if velocity != Vector2.ZERO:
		anim_tree["parameters/idle/blend_position"] = last_input_direction
		anim_tree["parameters/run/blend_position"] = last_input_direction
		anim_tree["parameters/dodge/blend_position"] = last_input_direction.x

func get_animation_lengths():
	attack_1_length = anim_player.get_animation("attack_right_1").length
	attack_2_length = anim_player.get_animation("attack_right_2").length

@rpc("any_peer","call_local")
func class_change(class_title: String, transform_time: float):
	is_paused = true
	# Reset variables and booleans
	reset_systems()
	
	# Reset ClassSynchronizer
	class_synchronizer.process_mode = 4
	class_synchronizer.public_visibility = false
	class_synchronizer.root_path = get_parent().get_path()
	
	# Clear current class node
	get_child(0).queue_free()
	
	current_class = class_title # Change current class ref
	
	# Instantiate new class
	var class_node = load("res://classes/" + class_title + ".tscn").instantiate()
	
	# Add new class node as child
	add_child(class_node)
	move_child(class_node,0)
	
	# Update stats to new class
	var new_stats = ClassManager.get_class_data(class_title)
	update_stats(new_stats)
	
	await get_tree().create_timer(2).timeout
	is_paused = false
	initialize_class_children()

func transform_done():
	# Set new class's children nodes and methods
	initialize_class_children()
	#$PlayerSynchronizer.root_path = get_path()

@rpc("any_peer","call_local")
func take_damage(incoming_dmg: float):
	var dmg_reduction = 1 - (armor /  10)
	var new_dmg = incoming_dmg * dmg_reduction
	current_health -= new_dmg
	HP_bar.value = current_health
	if current_health <= 0:
		die()

func die():
	dead.emit(player_id)
	reset_systems()
	queue_free()

func update_stats(stats: Array):
	armor = stats[0]
	base_damage = stats[1]
	damage = base_damage
	speed =  stats[2]
	dodge_speed_mult = stats[3]
	dodge_duration = stats[4]
	dodge_count = stats[5]
	temp_count = dodge_count
	
	#print("Armor:" + str(armor))
	#print("Damage:" + str(base_damage))
	#print("Speed" + str(speed))
	#print("Dodge Mult: " + str(dodge_speed_mult))
	#print("Dodge Duration: " + str(dodge_duration))
	#print("Dodge Count: " + str(dodge_count))

func reset_systems():
	is_dodging = false
	can_dodge = true
	is_attacking = false
	attack_index = 1
	if is_instance_valid(get_child(0).get_node("ComboTimer")):
		get_child(0).get_node("ComboTimer").stop()
	$DodgeTimer.stop()
	$IFrameTimer.stop()
	$DodgeResetTimer.stop()

@rpc("any_peer","call_local")
func toggle_pause(state):
	is_paused = state
	print("Paused: " + str(is_paused))

func initialize_class_children():
	anim_tree = get_node(current_class + "/AnimationTree")
	anim_tree.active = true
	anim_player = get_node(current_class + "/AnimationPlayer")
	hitbox = get_node(current_class + "/Hitbox")
	hitbox.player_id = player_id
	class_synchronizer.root_path = get_child(0).get_path()
	class_synchronizer.public_visibility = true
	class_synchronizer.process_mode = 3
	if current_class != "Base":
		attack_method = Callable(get_node(current_class), "attack")
		current_type = get_node(current_class).type

func create_camera():
	var camera = Camera2D.new()
	camera.enabled = true
	camera.zoom = Vector2(1.5, 1.5)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = get_viewport_rect().size.x
	camera.limit_bottom = get_viewport_rect().size.y
	add_child(camera)
	$Label.show()
