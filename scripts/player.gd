extends CharacterBody2D

@export var current_class = "Base"
@export var player_id = 1

var max_health: float = 100
var current_health: float
var armor: float = 0
var base_damage: float = 0
var damage: float = base_damage
var speed: float = 150.0
var dodge_speed_mult = 4
var dodge_duration = 0.6
var dodge_cooldown = 1.5 
var dodge_speed = 0.0

@onready var anim_tree: AnimationTree
@onready var anim_player: AnimationPlayer
@onready var game_manager: Node
@onready var player_manager: Node
@onready var class_node: Node2D

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
var last_mouse_pos: Vector2 = Vector2.ZERO

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)))
	game_manager = get_node("/root/Main/GameManager")
	player_manager = get_node("/root/Main/PlayerManager")

func _ready() -> void:
	player_id = name
	
	anim_tree = get_node(current_class).get_node("AnimationTree")
	anim_tree.active = true
	anim_player = get_node(current_class).get_node("AnimationPlayer")
	mouse_pos = get_global_mouse_position()
	
	$DodgeTimer.wait_time = dodge_duration
	dodge_speed = speed * dodge_speed_mult
	current_health = max_health
	temp_count = dodge_count

func _process(delta: float) -> void:
	if !is_multiplayer_authority():
		return
		
	if !is_paused:
		handle_input() # Input data
		move_and_slide() # Character movement
	
		if is_instance_valid(anim_tree):
			update_animation_parameters() # Update AnimationTree
	
		#StageManager.update_player_stats(player_id, max_health, current_health, damage)

func handle_input():
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
	
	if Input.is_action_just_pressed("dodge"):
		if can_dodge:
			start_dodge()
	
	if Input.is_action_just_pressed("attack"):
		mouse_pos = get_local_mouse_position()
		if current_class != "Base":
			if !is_attacking and !is_dodging:
				anim_tree["parameters/attack/blend_position"] = Vector2(mouse_pos.x, attack_index)
				last_mouse_pos = mouse_pos
				attack_method.call(attack_index)
		else:
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
	
	if current_class != "Base":
		if current_class == "archer":
			anim_tree["parameters/attack/blend_position"] = Vector2(mouse_pos.x, attack_index)
		else:
			anim_tree["parameters/attack/blend_position"] = Vector2(last_mouse_pos.x, attack_index)
	
	
	if velocity != Vector2.ZERO:
		anim_tree["parameters/idle/blend_position"] = last_input_direction
		anim_tree["parameters/run/blend_position"] = last_input_direction
		if current_class == "Base":
			anim_tree["parameters/dodge/blend_position"] = last_input_direction
		else:
			anim_tree["parameters/dodge/blend_position"] = last_input_direction.x

func class_change(class_title: String):
	reset_systems()
	is_paused = true
	if is_instance_valid(get_node(current_class)):
		get_node(current_class).queue_free()
	
	current_class = class_title
	
	var new_stats = ClassManager.get_class_data(class_title)
	update_stats(new_stats)
	
	var class_node = load("res://classes/" + class_title + ".tscn").instantiate()
	
	if !has_node(current_class):
		add_child(class_node)
		class_node = get_node(class_title)
		move_child(class_node,0)

	anim_tree = class_node.get_node("AnimationTree")
	anim_player = class_node.get_node("AnimationPlayer")
	attack_method = Callable(class_node, "attack")
	
	await get_tree().create_timer(2).timeout
	is_paused = false

func take_damage(damage: float):
	pass

func update_stats(stats: Array):
	armor = stats[0]
	base_damage = stats[1]
	damage = base_damage
	speed =  stats[2]
	dodge_speed_mult = stats[3]
	dodge_duration = stats[4]
	dodge_count = stats[5]
	temp_count = dodge_count
	
	print("Armor:" + str(armor))
	print("Damage:" + str(base_damage))
	print("Speed" + str(speed))
	print("Dodge Mult: " + str(dodge_speed_mult))
	print("Dodge Duration: " + str(dodge_duration))
	print("Dodge Count: " + str(dodge_count))

func reset_systems():
	is_dodging = false
	can_dodge = true
	is_attacking = false
	attack_index = 1

func toggle_pause(state):
	is_paused = state
	print("Paused" + str(is_paused))
