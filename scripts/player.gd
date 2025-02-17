extends CharacterBody2D

@export var pause_menu: PackedScene

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
var is_paused = true

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

func _enter_tree() -> void:
	ready.connect(Callable($/root/Main/GameManager,"_on_players_connected"))
	dead.connect(Callable($/root/Main/GameManager,"game_over"))
	dead.connect(Callable($/root/Main/MainUI,"game_over"))
	
	set_multiplayer_authority(int(str(name)))

func _ready() -> void:
	player_manager = get_node("/root/Main/PlayerManager")
	player_id = int(str(name))
	
	current_class = get_child(0).name
	attack_method = Callable(get_child(0), "attack")
	class_synchronizer = $ClassSynchronizer
	$PlayerSynchronizer.root_path = get_path()
	
	HP_bar = get_node("UI/HPBar")
	HP_bar.max_value = max_health
	HP_bar.value = max_health
	
	hitbox = get_node("Base/Hitbox")
	hitbox.player_id = player_id
	
	initialize_class_children()
	
	$DodgeTimer.wait_time = dodge_duration
	dodge_speed = speed * dodge_speed_mult
	current_health = max_health
	temp_count = dodge_count
	
	if player_id == 1:
		anim_tree["parameters/idle/blend_position"] = Vector2(1,0)
	
	# Set up camera for each
	if is_multiplayer_authority():
		create_camera()

func _process(delta: float) -> void:
	if is_multiplayer_authority():
		if !is_paused:
			mouse_pos = get_global_mouse_position()
			local_mouse_pos = get_local_mouse_position()
			handle_input() # Input data
			
			move_and_slide() # Character movement
			
			if is_instance_valid(anim_tree):
				update_animation_parameters() # Update AnimationTree
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
		if !is_paused:
			if !is_attacking and !is_dodging:
				StageManager.set_target.rpc(player_id,mouse_pos)
				last_mouse_pos = local_mouse_pos
				attack_method.call(attack_index)

func attack(index: float):
	pass

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

@rpc("any_peer","call_local")
func class_change(class_title: String, transform_time: float):
	is_paused = true
	# Reset variables and booleans
	reset_systems()
	
	# Disable ClassSynchronizer
	class_synchronizer.process_mode = Node.PROCESS_MODE_DISABLED
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
	
	# Enable ClassSynchronizer
	class_synchronizer.root_path = get_child(0).get_path()
	class_synchronizer.public_visibility = true
	class_synchronizer.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Update stats to new class
	var new_stats = ClassManager.get_class_data(class_title)
	update_stats(new_stats)
	
	await get_tree().create_timer(transform_time).timeout
	is_paused = false
	initialize_class_children()

func transform_done(): # NOT USED
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
	
	# Disable ClassSynchronizer
	class_synchronizer.process_mode = Node.PROCESS_MODE_DISABLED
	class_synchronizer.public_visibility = false
	class_synchronizer.root_path = get_parent().get_path()
	
	# Remove player node
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
	if current_class != "archer":
		get_child(0).get_node("ComboTimer").stop()
	else:
		get_child(0).get_node("ChargeTimer").stop()
		get_child(0).get_node("ChargeAnimTimer").stop()
	$DodgeTimer.stop()
	$IFrameTimer.stop()
	$DodgeResetTimer.stop()

@rpc("any_peer","call_local")
func toggle_pause():
	is_paused = !is_paused
	if is_paused:
		add_child(pause_menu.instantiate())
	elif !is_paused:
		get_node("PauseMenu").queue_free()

func initialize_class_children():
	anim_tree = get_node(current_class + "/AnimationTree")
	anim_tree.active = true
	anim_player = get_node(current_class + "/AnimationPlayer")
	hitbox = get_node(current_class + "/Hitbox")
	hitbox.player_id = player_id
	attack_method = Callable(get_child(0), "attack")
	current_type = get_child(0).type

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
