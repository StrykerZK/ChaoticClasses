extends CharacterBody2D

@export var current_class = "Base"
@export var player_id = 1

var max_health: float = 100
var current_health: float
var armor: float = 0
var damage: float = 0
var speed: float = 150.0
var dodge_speed_mult = 4
var dodge_duration = 0.6
var dodge_cooldown = 1.2
var dodge_speed = 0.0
var combo_timer = 1.5

@onready var anim_tree: AnimationTree
@onready var anim_player: AnimationPlayer
@onready var game_manager: Node
@onready var class_node: Node2D

var direction: Vector2 = Vector2.ZERO
var last_input_direction: Vector2 = Vector2(1,0)
var changing_class = false
var is_paused = false
var is_dodging = false
var can_dodge = true
var is_attacking = false
var attack_index = 1
var attack_1_length: float = 0.3
var attack_2_length: float = 0.3
var attack_3_length: float = 0.5

func _enter_tree() -> void:
	game_manager = get_node("/root/Main/GameManager")

func _ready() -> void:
	anim_tree = get_node(current_class).get_node("AnimationTree")
	anim_tree.active = true
	anim_player = get_node(current_class).get_node("AnimationPlayer")
	
	$DodgeTimer.wait_time = dodge_duration
	dodge_speed = speed * dodge_speed_mult
	current_health = max_health

func _process(delta: float) -> void:
	handle_input() # Input data
	move_and_slide() # Character movement
	
	if is_instance_valid(anim_tree) and is_multiplayer_authority():
		update_animation_parameters() # Update AnimationTree
	
	StageManager.update_player_stats(player_id, max_health, current_health, damage)

func handle_input():
	if !is_dodging and !is_attacking:
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
		if can_dodge and !is_dodging:
			start_dodge()
	
	if Input.is_action_just_pressed("attack"):
		if current_class != "Base" and !is_attacking:
			attack(attack_index)
		else:
			pass

func start_dodge():
	is_dodging = true
	can_dodge = false
	activate_i_frame(dodge_duration)
	
	dodge_speed = speed * dodge_speed_mult
	velocity = last_input_direction * dodge_speed
	
	# Tween the dodge speed to 0 smoothly
	var tween = get_tree().create_tween()
	tween.tween_property(self, "dodge_speed", 0.0, dodge_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	$DodgeTimer.wait_time = dodge_duration
	$DodgeTimer.start()

func end_dodge():
	is_dodging = false
	velocity = Vector2.ZERO
	await get_tree().create_timer(dodge_cooldown).timeout
	can_dodge = true

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
	
	if velocity != Vector2.ZERO:
		anim_tree["parameters/idle/blend_position"] = last_input_direction
		anim_tree["parameters/run/blend_position"] = last_input_direction
		if current_class == "Base":
			anim_tree["parameters/dodge/blend_position"] = last_input_direction
		else:
			anim_tree["parameters/dodge/blend_position"] = last_input_direction.x
	
	if current_class != "Base":
		anim_tree["parameters/attack/blend_position"] = Vector2(last_input_direction.x, attack_index)

func class_change(class_title: String):
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
	get_animation_lengths()

func take_damage(source: Area2D):
	if player_id == 1:
		current_health -= StageManager.p2_damage
	elif player_id == 2:
		current_health -= StageManager.p1_damage

func attack(index: int):
	is_attacking = true
	$ComboTimer.wait_time = combo_timer
	match index:
		1:
			print("attack 1")
			$ComboTimer.start()
			await get_tree().create_timer(attack_1_length).timeout
			is_attacking = false
			attack_index += 1
		2:
			print("attack 2")
			$ComboTimer.start()
			await get_tree().create_timer(attack_2_length).timeout
			is_attacking = false
			attack_index += 1
		3:
			print("attack 3")
			$ComboTimer.wait_time = 0.6
			$ComboTimer.start()

func get_animation_lengths():
	attack_1_length = anim_player.get_animation("attack_right_1").length
	print("Attack 1: " + str(attack_1_length))
	attack_2_length = anim_player.get_animation("attack_right_2").length
	print("Attack 2: " + str(attack_2_length))
	attack_3_length = anim_player.get_animation("attack_right_3").length
	print("Attack 3: " + str(attack_3_length))

func update_stats(stats: Array):
	armor = stats[0]
	damage = stats[1]
	speed =  stats[2]
	dodge_speed_mult = stats[3]
	dodge_duration = stats[4]

func toggle_pause(state):
	is_paused = state
	print("Paused" + str(is_paused))

func _on_combo_timer_timeout() -> void:
	is_attacking = false
	attack_index = 1

func _on_button_pressed() -> void:
	class_change("hero")
	$Button.queue_free()
