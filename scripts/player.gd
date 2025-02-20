extends CharacterBody2D

@export var current_class: String = "Base"
@export var current_type: String = "melee"
@export var player_id: int = 1
var current_class_node: Node

signal dead(int)

@export var max_health: float = 200
var current_health: float = max_health
var armor: float = 0
var base_damage: float = 5
var damage: float = base_damage
var speed: float = 150.0
var dodge_speed_mult: float = 4
var dodge_duration: float = 0.6
@export var dodge_cooldown: float = 1.5 
var dodge_speed: float = 0.0
@export var dash_speed: float = 0.0
@export var dash_duration: float = 0.2

# Misc variables
@onready var anim_tree: AnimationTree
@onready var anim_player: AnimationPlayer
@onready var class_synchronizer: MultiplayerSynchronizer
@onready var player_manager: Node
@onready var hitbox: Area2D

var direction: Vector2 = Vector2.ZERO
var last_input_direction: Vector2 = Vector2(1,0)
var is_paused: bool = true
var is_dead: bool = false

# Variables for dodging
var is_dodging: bool = false
var can_dodge: bool = true
var dodge_count: int = 1
var temp_count: int = dodge_count
var dodge_tween: Tween

# Variables for attacking
var is_attacking: bool = false
var can_attack: bool = true
var attack_index: float = 1.0
var mouse_pos: Vector2 = Vector2.ZERO
var local_mouse_pos: Vector2 = Vector2.ZERO
var last_mouse_pos: Vector2 = Vector2.ZERO
var dash_tween: Tween

func _enter_tree() -> void:
	ready.connect(Callable($/root/Main/GameManager,"_on_players_connected"))
	dead.connect(Callable($/root/Main/GameManager,"game_over"))
	dead.connect(Callable($/root/Main/MainUI,"game_over"))
	dead.connect(Callable(StageManager,"game_over"))
	
	set_multiplayer_authority(int(str(name)))

func _ready() -> void:
	player_manager = get_node("/root/Main/PlayerManager")
	player_id = int(str(name))
	
	current_class_node = get_child(0)
	current_class = current_class_node.name
	current_type = current_class_node.type
	class_synchronizer = $ClassSynchronizer
	$PlayerSynchronizer.root_path = get_path()
	
	hitbox = get_node("Base/Hitbox")
	hitbox.player_id = player_id
	
	initialize_class_children()
	
	$DodgeTimer.wait_time = dodge_duration
	$DodgeCooldownTimer.wait_time = dodge_cooldown
	dodge_speed = speed * dodge_speed_mult
	
	# Face players correct way
	if player_id == 1:
		anim_tree["parameters/idle/blend_position"] = Vector2(1,0)
	else:
		anim_tree["parameters/idle/blend_position"] = Vector2(-1,0)
	
	# Set up
	if is_multiplayer_authority():
		StageManager.update_player_stats.rpc(player_id, current_health)
	elif !is_multiplayer_authority():
		$Camera.queue_free()

func _process(delta: float) -> void:
	if is_multiplayer_authority():
		if !is_paused:
			mouse_pos = get_global_mouse_position()
			local_mouse_pos = get_local_mouse_position()
			
			if !is_dead:
				handle_input() # Input data
			
			move_and_slide() # Character movement
			
			if is_instance_valid(anim_tree) and !is_dead:
				update_animation_parameters() # Update AnimationTree

func handle_input():
	if current_type == "melee": # If melee, don't move while attacking
		if !is_dodging:
			direction = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
		last_input_direction = direction
		
		if is_attacking:
			velocity = position.direction_to(get_global_mouse_position()) * dash_speed
		else:
			if direction:
				velocity = direction * speed
			else:
				velocity = Vector2.ZERO
		
		if is_dodging:
			velocity = last_input_direction * dodge_speed
		
	else: # If ranged, move while attacking
		if !is_dodging:
			direction = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
		last_input_direction = direction
		
		if is_dodging:
			velocity = last_input_direction * dodge_speed
		else:
			if direction:
				velocity = direction * speed
			else:
				velocity = Vector2.ZERO
	
	
	if Input.is_action_just_pressed("dodge"):
		if can_dodge:
			start_dodge()
	
	if Input.is_action_just_pressed("attack"):
		if !is_attacking and !is_dodging:
			if can_attack:
				StageManager.set_target.rpc(player_id,mouse_pos)
				last_mouse_pos = local_mouse_pos
				current_class_node.attack.rpc(attack_index)
				can_attack = false

func tween_dash_value():
	if dash_tween:
		dash_tween.kill()
	dash_tween = create_tween()
	dash_tween.tween_property(self, "dash_speed", 0.0, dash_duration)\
	.set_trans(Tween.TRANS_QUAD)\
	.set_ease(Tween.EASE_OUT)

func tween_dodge_value():
	if dodge_tween:
		dodge_tween.kill()
	dodge_tween = create_tween()
	dodge_tween.tween_property(self, "dodge_speed", 0.0, dodge_duration)\
	.set_trans(Tween.TRANS_QUAD)\
	.set_ease(Tween.EASE_OUT)

func start_dodge():
	is_attacking = false
	is_dodging = true
	can_dodge = false
	can_attack = false
	
	activate_i_frame(dodge_duration)
	
	dodge_speed = speed * dodge_speed_mult
	
	# Tween the dodge speed to 0 smoothly
	tween_dodge_value()
	
	$DodgeTimer.wait_time = dodge_duration
	$DodgeTimer.start()

func end_dodge():
	is_dodging = false
	can_attack = true
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
	$DodgeCooldownTimer.wait_time = dodge_cooldown
	$DodgeCooldownTimer.start()
	await $DodgeCooldownTimer.timeout
	while is_attacking:
		await get_tree().create_timer(0.1).timeout # Wait for attack to finish
	can_dodge = true
	temp_count = dodge_count

func activate_i_frame(value: float):
	$Hurtbox.set_deferred("monitorable", false)
	$IFrameTimer.start(value)
	await $IFrameTimer.timeout
	deactivate_i_frame()
	
func deactivate_i_frame():
	$Hurtbox.set_deferred("monitorable", true)

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

@rpc("any_peer","call_local")
func class_change(class_title: String):
	# Reset variables and booleans
	reset_systems()
	
	# Disable ClassSynchronizer
	class_synchronizer.process_mode = Node.PROCESS_MODE_DISABLED
	class_synchronizer.public_visibility = false
	class_synchronizer.root_path = get_parent().get_path()
	
	# Play transform FX
	$PlayerFX.play("transform")
	
	# Clear current class node
	await get_tree().create_timer(0.4).timeout
	current_class_node.queue_free()
	
	current_class = class_title # Change current class ref
	
	# Instantiate new class
	var class_node = load("res://classes/" + class_title + ".tscn").instantiate()
	
	# Add new class node as child
	await get_tree().create_timer(1.4).timeout
	add_child(class_node)
	move_child(class_node,0)
	current_class_node = get_child(0)
	
	# Enable ClassSynchronizer
	class_synchronizer.root_path = current_class_node.get_path()
	class_synchronizer.public_visibility = true
	class_synchronizer.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Update stats to new class
	var new_stats = ClassManager.get_class_data(class_title)
	update_stats(new_stats)
	
	initialize_class_children()
	
	if is_multiplayer_authority() and multiplayer.is_server():
		$/root/Main/GameManager.toggle_pause.rpc()
		StageManager.update_game_state.rpc("In Game")

func take_damage(incoming_dmg: float):
	# Calculate armor into damage
	var dmg_reduction = 1 - (armor /  10)
	var new_dmg = incoming_dmg * dmg_reduction
	current_health -= new_dmg
	
	# Update Info UI
	if is_multiplayer_authority():
		StageManager.update_player_stats.rpc(player_id, current_health)
	
	# I-Frame and flasing effect
	activate_i_frame(0.5)
	current_class_node.get_child(0).modulate.s = 50
	
	# Die if equal or below 0 health
	if current_health <= 0:
		die()
		return
	
	# Slowdown effect
	Engine.time_scale = 0.2
	await get_tree().create_timer(0.1).timeout
	Engine.time_scale = 1
	
	# Finish flashing effect
	await $IFrameTimer.timeout
	current_class_node.get_child(0).modulate.s = 0

func die():
	is_dead = true
	reset_systems()
	disable_collisions.rpc()
	
	# Disable ClassSynchronizer
	class_synchronizer.process_mode = Node.PROCESS_MODE_DISABLED
	class_synchronizer.public_visibility = false
	class_synchronizer.root_path = get_parent().get_path()
	
	# Get all player nodes
	var players = get_tree().get_nodes_in_group("players")
	
	# Slowdown effect and zoom
	current_class_node.get_child(0).modulate.s = 50
	for i in players:
		i.zoom_camera(2.5)
	Engine.time_scale = 0.1
	await get_tree().create_timer(0.1).timeout
	Engine.time_scale = 1
	for i in players:
		i.zoom_camera(1.5)
	
	# Yeet player across map
	for i in players:
		if i.name != str(player_id):
			velocity = position.direction_to(i.position) * -1500
	
	dead.emit(player_id)
	
	await get_tree().create_timer(2).timeout
	
	# Remove player node
	queue_free()

@rpc("any_peer","call_local")
func disable_collisions():
	$Collisionbox.set_deferred("disabled", true)
	$Hurtbox.set_deferred("monitoring", false)
	$Hurtbox.set_deferred("monitorable", false)

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
	is_attacking = false
	is_dodging = false
	can_attack = true
	current_class_node.get_child(0).modulate.s = 0 # Reset iframe red flash
	current_class_node.stop_systems()
	$DodgeTimer.stop()
	$DodgeResetTimer.stop()
	$IFrameTimer.stop()
	deactivate_i_frame()
	attack_index = 1
	damage = base_damage
	can_dodge = true

@rpc("any_peer","call_local")
func toggle_pause():
	is_paused = !is_paused

func initialize_class_children():
	anim_tree = get_node(current_class + "/AnimationTree")
	anim_tree.active = true
	anim_player = get_node(current_class + "/AnimationPlayer")
	hitbox = get_node(current_class + "/Hitbox")
	hitbox.player_id = player_id
	current_type = current_class_node.type

func create_camera():
	var camera = Camera2D.new()
	camera.name = "Camera"
	camera.enabled = true
	camera.zoom = Vector2(1.5, 1.5)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = get_viewport_rect().size.x
	camera.limit_bottom = get_viewport_rect().size.y
	add_child(camera)

func zoom_camera(amount: float):
	if $Camera:
		$Camera.zoom = Vector2(amount,amount)

func smooth_camera(setting: String):
	if $Camera:
		if setting == "limit":
			$Camera.limit_smoothed = !$Camera.limit_smoothed
		elif setting == "position":
			$Camera.position_smoothing_enabled = !$Camera.position_smoothing_enabled
		elif setting == "rotation":
			$Camera.rotation_smoothing_enabled = !$Camera.rotation_smoothing_enabled
