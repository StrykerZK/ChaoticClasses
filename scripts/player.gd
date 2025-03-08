extends CharacterBody2D

var current_class: String = "base"
var current_type: String = "melee"
var player_id: int = 1
var current_class_node: Node
var ghost_scene = preload("res://utility/ghost.tscn")

signal dead(int)

@export var max_health: float = 200
var current_health: float = max_health
var armor: float = 0
var base_damage: float = 5
var damage: float = base_damage
var base_speed: float = 250.0
var speed: float = base_speed
var dodge_speed_mult: float = 4
var dodge_duration: float = 0.6
@export var dodge_cooldown: float = 1.0
var dodge_speed: float = 0.0
@export var dash_speed: float = 0.0
@export var dash_duration: float = 0.2

# Misc variables
@onready var anim_tree: AnimationTree
@onready var anim_player: AnimationPlayer
@onready var player_manager: Node
@onready var hitbox: Area2D

var direction: Vector2 = Vector2.ZERO
var last_input_direction: Vector2 = Vector2(1,0)
var is_paused: bool = true
var is_dead: bool = false
var is_transforming: bool = false

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
var last_attack_pos: Vector2 = Vector2.ZERO
var dash_tween: Tween

# Variables for spells
var spell_1_ready: bool = true
var spell_2_ready: bool = true
var in_spell_1: bool = false
var in_spell_2: bool = false
var is_slowed: bool = false
var is_stunned: bool = false
var is_rooted: bool = false

func _enter_tree() -> void:
	ready.connect(Callable($/root/Main/GameManager,"_on_players_connected"))
	#dead.connect(Callable(StageManager,"game_over"))
	dead.connect(Callable($/root/Main/GameManager,"game_over"))
	#dead.connect(Callable($/root/Main/MainUI,"game_over"))
	#dead.connect(Callable($/root/Main,"game_over"))
	
	player_id = int(str(name))
	set_multiplayer_authority(player_id)

func _ready() -> void:
	player_manager = get_node("/root/Main/PlayerManager")
	
	change_camera_focus(Vector2(get_viewport_rect().size.x / 2,\
	get_viewport_rect().size.y / 2))
	
	current_class_node = get_child(0)
	current_class = current_class_node.name
	current_type = current_class_node.type
	$PlayerSynchronizer.root_path = get_path()
	$PlayerSynchronizer.set_multiplayer_authority(player_id)
	
	hitbox = get_node("base/Hitbox")
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
				if !is_stunned:
					handle_input() # Input data
				update_animation_parameters.rpc() # Update animations
			
			move_and_slide() # Character movement

func handle_input():
	
	# Movement
	if current_type == "melee": # If melee, don't move while attacking
		if !is_dodging:
			direction = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
		if direction != Vector2.ZERO:
			last_input_direction = direction
		
		if !is_rooted:
			if is_attacking or in_spell_1 or in_spell_2:
				if dash_speed != 0:
					velocity = position.direction_to($Target.global_position) * dash_speed
				else:
					velocity = Vector2.ZERO
			else:
				if direction:
					velocity = direction * speed
				else:
					velocity = Vector2.ZERO
			
			if is_dodging:
				velocity = last_input_direction * dodge_speed
		else:
			velocity = Vector2.ZERO
		
	else: # If ranged, move while attacking
		if !is_dodging:
			direction = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
		if direction != Vector2.ZERO:
			last_input_direction = direction
		
		if !is_rooted:
			if in_spell_1 or in_spell_2:
				if dash_speed != 0:
					velocity = position.direction_to($Target.global_position) * dash_speed
				else:
					velocity = Vector2.ZERO
			else:
				if direction:
					velocity = direction * speed
				else:
					velocity = Vector2.ZERO
			
			if is_dodging:
				velocity = last_input_direction * dodge_speed
		else:
			velocity = Vector2.ZERO
	
	# Dodging
	if Input.is_action_just_pressed("dodge") and !is_rooted:
		if can_dodge:
			start_dodge.rpc()
	
	# Attacking
	if Input.is_action_just_pressed("attack"):
		if !is_attacking and !is_dodging and !in_spell_1 and !in_spell_2:
			if can_attack:
				StageManager.set_target.rpc(player_id,mouse_pos)
				$Target.global_position = get_global_mouse_position()
				current_class_node.attack.rpc(attack_index)
				can_attack = false
	
	# Spell 1
	if Input.is_action_just_pressed("spell_1"):
		if !is_attacking and !is_dodging and spell_1_ready and !in_spell_2:
			StageManager.set_target.rpc(player_id,mouse_pos)
			$Target.global_position = get_global_mouse_position()
			current_class_node.spell_1.rpc()
			spell_1_ready = false
	
	# Spell 2
	if Input.is_action_just_pressed("spell_2"):
		if !is_attacking and !is_dodging and spell_2_ready and !in_spell_1:
			StageManager.set_target.rpc(player_id,mouse_pos)
			$Target.global_position = get_global_mouse_position()
			current_class_node.spell_2.rpc()
			spell_2_ready = false

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

@rpc("any_peer","call_local")
func start_dodge():
	is_attacking = false
	if in_spell_1 or in_spell_2:
		current_class_node.stop_spells()
	in_spell_1 = false
	in_spell_2 = false
	is_dodging = true
	can_dodge = false
	can_attack = false
	
	activate_i_frame(dodge_duration)
	
	dodge_speed = speed * dodge_speed_mult
	
	# Tween the dodge speed to 0 smoothly
	tween_dodge_value()
	
	ghost_effect()
	$GhostTimer.start()
	$DodgeTimer.wait_time = dodge_duration
	$DodgeTimer.start()

func end_dodge():
	is_dodging = false
	can_attack = true
	$GhostTimer.stop()
	if temp_count > 1:
		can_dodge = true
		temp_count -= 1
		$DodgeResetTimer.stop()
		$DodgeResetTimer.start()
	elif temp_count == 1:
		$DodgeResetTimer.stop()
		dodge_on_cooldown()

func ghost_effect():
	var ghost: Sprite2D = ghost_scene.instantiate()
	var sprite: Sprite2D = current_class_node.get_child(0)
	$/root/Main.add_child(ghost)
	
	ghost.global_position = global_position
	ghost.texture = sprite.texture
	ghost.vframes = sprite.vframes
	ghost.hframes = sprite.hframes
	ghost.frame = sprite.frame
	ghost.flip_h = sprite.flip_h
	ghost.scale = sprite.scale

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

@rpc("any_peer","call_local")
func update_animation_parameters():
	if !is_instance_valid(anim_tree):
		return
	
	anim_tree.set("parameters/conditions/is_dodging", is_dodging)
	anim_tree.set("parameters/conditions/is_attacking", is_attacking)
	anim_tree.set("parameters/conditions/in_spell_1", in_spell_1)
	anim_tree.set("parameters/conditions/in_spell_2", in_spell_2)
	
	if !is_dodging and !is_attacking and !in_spell_1 and !in_spell_2:
		anim_tree.set("parameters/conditions/idle", velocity == Vector2.ZERO)
		anim_tree.set("parameters/conditions/is_running", velocity != Vector2.ZERO)
	else:
		anim_tree.set("parameters/conditions/idle", false)
		anim_tree.set("parameters/conditions/is_running", false)
	
	if current_class == "archer":
		anim_tree["parameters/attack/blend_position"] = Vector2(local_mouse_pos.x, attack_index)
	else:
		if dash_speed != 0:
			anim_tree["parameters/attack/blend_position"] = Vector2($Target.position.x, attack_index)
		else:
			anim_tree["parameters/attack/blend_position"] = Vector2(local_mouse_pos.x, attack_index)
	
	# Spells
	if dash_speed != 0:
		anim_tree["parameters/spell1/blend_position"] = $Target.position.x
		anim_tree["parameters/spell2/blend_position"] = $Target.position.x
	else:
		anim_tree["parameters/spell1/blend_position"] = local_mouse_pos.x
		anim_tree["parameters/spell2/blend_position"] = local_mouse_pos.x
	
	if velocity != Vector2.ZERO:
		anim_tree["parameters/idle/blend_position"] = last_input_direction
		anim_tree["parameters/run/blend_position"] = last_input_direction
		anim_tree["parameters/dodge/blend_position"] = last_input_direction.x

@rpc("any_peer","call_local")
func class_change(class_title: String):
	# Start countdown animation
	is_transforming = true
	$PlayerFX.stop()
	$PlayerFX.show()
	$PlayerFX.play("countdown")
	await $PlayerFX.animation_finished
	
	if !is_transforming:
		return
	
	# Pause for transformation
	StageManager.update_game_state.rpc("Transforming")
	if is_multiplayer_authority(): #and multiplayer.is_server():
		$/root/Main/GameManager.toggle_pause.rpc(0)
	
	# Reset variables and booleans
	reset_systems()
	
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
	
	# Update stats to new class
	var new_stats = ClassManager.get_class_data(class_title)
	update_stats(new_stats)
	
	initialize_class_children()
	
	if is_multiplayer_authority(): #and multiplayer.is_server():
		$/root/Main/GameManager.toggle_pause.rpc(0)
	
	is_transforming = false
	await $PlayerFX.animation_finished
	$PlayerFX.hide()
	StageManager.update_game_state.rpc("In Game")

func debuff(type: String, amount: float, duration: float):
	var remaining_debuff: String = ""
	var debuff_time: float = 0
	var prev_amount: float = 0
	if is_slowed:
		remaining_debuff = "slow"
		prev_amount = speed / base_speed
	elif is_rooted:
		remaining_debuff = "root"
	elif is_stunned:
		remaining_debuff = "stun"
	debuff_time = $DebuffTimer.time_left - duration
	match type:
		"slow":
			is_slowed = true
			$DebuffFX.stop()
			$DebuffFX.play("slow")
			$DebuffFX.show()
			speed = speed * (1 - amount)
			$DebuffTimer.stop()
			$DebuffTimer.wait_time = duration
			$DebuffTimer.start()
			await $DebuffTimer.timeout
			speed = base_speed
			is_slowed = false
		"root":
			is_rooted = true
			$DebuffFX.stop()
			$DebuffFX.play("root")
			$DebuffFX.show()
			$DebuffTimer.stop()
			$DebuffTimer.wait_time = duration
			$DebuffTimer.start()
			await $DebuffTimer.timeout
			is_rooted = false
		"stun":
			is_stunned = true
			$DebuffFX.play("stun")
	$DebuffFX.stop()
	$DebuffFX.hide()
	if !remaining_debuff.is_empty():
		debuff(remaining_debuff,prev_amount,debuff_time)

func take_damage(incoming_dmg: float):
	if incoming_dmg <= 0:
		return
	
	if is_multiplayer_authority() and !is_dead: # Add this for any dmg sync errors
		# Calculate armor into damage
		var dmg_reduction = 1 - (armor /  10)
		var new_dmg = incoming_dmg * dmg_reduction
		current_health -= new_dmg
		# Update Info UI
		StageManager.update_player_stats.rpc(player_id, current_health)
	
	# I-Frame and hit effect
	activate_i_frame(0.5)
	$HitFX.play("hit")
	
	# Die if equal or below 0 health
	if current_health <= 0:
		die.rpc() # Add RPC for dmg sync errors
		return
	
	# Flashing effect
	current_class_node.get_child(0).modulate.s = 50
	await $IFrameTimer.timeout
	current_class_node.get_child(0).modulate.s = 0

@rpc("any_peer","call_local","reliable")
func die():
	is_dead = true
	is_transforming = false
	reset_systems()
	disable_collisions()
	
	# Get all player nodes
	var players = get_tree().get_nodes_in_group("players")
	
	# Slowdown effect and zoom
	current_class_node.get_child(0).modulate.s = 50
	for i in players:
		if i.player_id != player_id:
			if !is_multiplayer_authority():
				i.change_camera_focus(global_position)
		i.zoom_camera(2.5)
	Engine.time_scale = 0.1
	use_utility_timer(0.15)
	await $UtilityTimer.timeout
	Engine.time_scale = 1
	for i in players:
		if i.player_id != player_id:
			if !is_multiplayer_authority():
				i.zoom_camera(1.0)
		else:
			i.zoom_camera(1.5)
	
	# Yeet player across map
	for i in players:
		if i.name != str(player_id):
			velocity = position.direction_to(i.position) * -1800
	
	if multiplayer.is_server():
		await get_tree().create_timer(0.7).timeout
		dead.emit(player_id)

func disable_collisions():
	$Collisionbox.set_deferred("disabled", true)
	$Hurtbox.set_deferred("monitoring", false)
	$Hurtbox.set_deferred("monitorable", false)

func update_stats(stats: Array):
	armor = stats[0]
	base_damage = stats[1]
	damage = base_damage
	base_speed =  stats[2]
	speed = base_speed
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
	spell_1_ready = true
	spell_2_ready = true
	in_spell_1 = false
	in_spell_2 = false
	current_class_node.get_child(0).modulate.s = 0 # Reset iframe red flash
	current_class_node.stop_systems()
	current_class_node.stop_spells()
	$GhostTimer.stop()
	$DodgeTimer.stop()
	$DodgeResetTimer.stop()
	$IFrameTimer.stop()
	$UtilityTimer.stop()
	$DebuffFX.stop()
	$DebuffFX.hide()
	$DebuffTimer.stop()
	is_stunned = false
	is_rooted = false
	is_slowed = false
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

func use_utility_timer(duration: float):
	$UtilityTimer.stop()
	$UtilityTimer.wait_time = duration
	$UtilityTimer.start()

func create_camera():
	if $Camera:
		return
	var camera = Camera2D.new()
	camera.name = "Camera"
	camera.enabled = true
	camera.zoom = Vector2(1.5, 1.5)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5
	#camera.limit_left = 0
	#camera.limit_top = 0
	#camera.limit_right = get_viewport_rect().size.x
	#camera.limit_bottom = get_viewport_rect().size.y
	#camera.limit_smoothed = true
	add_child(camera)

func zoom_camera(amount: float):
	if is_multiplayer_authority():
		$Camera.zoom = Vector2(amount,amount)

func smooth_camera(setting: String):
	if is_multiplayer_authority():
		if setting == "limit":
			$Camera.limit_smoothed = !$Camera.limit_smoothed
		elif setting == "position":
			$Camera.position_smoothing_enabled = !$Camera.position_smoothing_enabled
		elif setting == "rotation":
			$Camera.rotation_smoothing_enabled = !$Camera.rotation_smoothing_enabled

func change_camera_focus(target: Vector2):
	if is_multiplayer_authority():
		$Camera.global_position = target

func reset_camera_focus():
	if is_multiplayer_authority():
		change_camera_focus(global_position)
