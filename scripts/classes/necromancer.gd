extends Node2D

@export var attack_scene: PackedScene
@export var spell_1_scene: PackedScene
@export var spell_2_scene: PackedScene

@onready var player: CharacterBody2D
@onready var anim_player: AnimationPlayer
@onready var main_node: Node
@onready var dodge_timer: Timer

var attack_1_length: float = 0.3
var attack_2_length: float = 0.3
var combo_timer = 1.5
var base_speed = 300
var type = "ranged"

func _ready() -> void:
	player = get_parent()
	dodge_timer = player.get_node("DodgeCooldownTimer")
	anim_player = $AnimationPlayer
	base_speed = player.speed
	main_node = get_tree().root.get_node("Main")
	
	get_animation_lengths()

@rpc("any_peer","call_local")
func attack(index: float):
	player.speed = player.speed * 0.1
	player.can_dodge = false
	player.is_attacking = true
	$ComboTimer.stop()
	$ComboTimer.wait_time = combo_timer
	match index:
		1.0:
			$ComboTimer.start()
			spawn_attack(player.attack_index)
			use_attack_timer(attack_1_length)
		2.0:
			$ComboTimer.start()
			spawn_attack(player.attack_index)
			use_attack_timer(attack_2_length)

func spawn_attack(index: float):
	var circle = attack_scene.instantiate()
	circle.position = StageManager.get_target(player.player_id)
	circle.damage = player.damage
	circle.player_id = player.player_id
	main_node.spawn(circle)

func use_attack_timer(time: float):
	$AttackTimer.wait_time = time
	$AttackTimer.start()
	await $AttackTimer.timeout
	player.is_attacking = false
	if player.attack_index == 2.0:
		player.attack_index = 1.0 # Reset after 3rd attack
		$ComboTimer.wait_time = 0.5
		$ComboTimer.start()
	else:
		player.attack_index += 1.0
		player.can_attack = true
	if !player.is_slowed and !player.is_rooted:
		player.speed = base_speed
	if dodge_timer.is_stopped(): player.can_dodge = true

@rpc("any_peer","call_local")
func spell_1():
	player.in_spell_1 = true
	player.can_dodge = false
	
	var summon_offset: float = 40.0
	
	var top_left_pos = global_position + Vector2(-summon_offset, -summon_offset)
	var top_right_pos = global_position + Vector2(summon_offset, -summon_offset)
	var bottom_left_pos = global_position + Vector2(-summon_offset, summon_offset)
	var bottom_right_pos = global_position + Vector2(summon_offset, summon_offset)
	
	top_left_pos = adjust_spawn_position(top_left_pos)
	top_right_pos = adjust_spawn_position(top_right_pos)
	bottom_left_pos = adjust_spawn_position(bottom_left_pos)
	bottom_right_pos = adjust_spawn_position(bottom_right_pos)
	
	await get_tree().create_timer(0.3).timeout
	
	if top_left_pos != Vector2.INF:
		var top_left_summon = spell_1_scene.instantiate()
		top_left_summon.position = top_left_pos
		top_left_summon.player_id = player.player_id
		main_node.spawn(top_left_summon)
	
	if top_right_pos != Vector2.INF:
		var top_right_summon = spell_1_scene.instantiate()
		top_right_summon.position = top_right_pos
		top_right_summon.player_id = player.player_id
		main_node.spawn(top_right_summon)
	
	if bottom_left_pos != Vector2.INF:
		var bottom_left_summon = spell_1_scene.instantiate()
		bottom_left_summon.position = bottom_left_pos
		bottom_left_summon.player_id = player.player_id
		main_node.spawn(bottom_left_summon)
	
	if bottom_right_pos != Vector2.INF:
		var bottom_right_summon = spell_1_scene.instantiate()
		bottom_right_summon.position = bottom_right_pos
		bottom_right_summon.player_id = player.player_id
		main_node.spawn(bottom_right_summon)
	
	await get_tree().create_timer(1.0).timeout
	if dodge_timer.is_stopped(): player.can_dodge = true
	start_spell_1_cooldown()

func _on_spell_1_timer_timeout() -> void:
	player.spell_1_ready = true

func start_spell_1_cooldown(): # 7 sec cd
	player.in_spell_1 = false
	var duration = 7.0
	$Spell1Timer.wait_time = duration
	$Spell1Timer.start()
	player.queue_spell_cooldown(duration, 1)

@rpc("any_peer","call_local")
func spell_2():
	player.in_spell_2 = true
	player.can_dodge = false
	
	var summon_offset: float = 40.0
	
	var top_pos = global_position + Vector2(0, -summon_offset)
	var bottom_left_pos = global_position + Vector2(-summon_offset, summon_offset)
	var bottom_right_pos = global_position + Vector2(summon_offset, summon_offset)
	
	top_pos = adjust_spawn_position(top_pos)
	bottom_left_pos = adjust_spawn_position(bottom_left_pos)
	bottom_right_pos = adjust_spawn_position(bottom_right_pos)
	
	await get_tree().create_timer(0.3).timeout
	
	if top_pos != Vector2.INF:
		var top_summon = spell_2_scene.instantiate()
		top_summon.position = top_pos
		top_summon.player_id = player.player_id
		main_node.spawn(top_summon)
	
	if bottom_left_pos != Vector2.INF:
		var bottom_left_summon = spell_2_scene.instantiate()
		bottom_left_summon.position = bottom_left_pos
		bottom_left_summon.player_id = player.player_id
		main_node.spawn(bottom_left_summon)
	
	if bottom_right_pos != Vector2.INF:
		var bottom_right_summon = spell_2_scene.instantiate()
		bottom_right_summon.position = bottom_right_pos
		bottom_right_summon.player_id = player.player_id
		main_node.spawn(bottom_right_summon)
	
	await get_tree().create_timer(1.0).timeout
	if dodge_timer.is_stopped(): player.can_dodge = true
	start_spell_2_cooldown()

func _on_spell_2_timer_timeout() -> void:
	player.spell_2_ready = true

func start_spell_2_cooldown(): # 7 sec cd
	player.in_spell_2 = false
	var duration = 7.0
	$Spell2Timer.wait_time = duration
	$Spell2Timer.start()
	player.queue_spell_cooldown(duration, 2)

func stop_spells():
	if player.in_spell_1:
		$Spell1Timer.stop()
		start_spell_1_cooldown()
	if player.in_spell_2:
		$Spell2Timer.stop()
		start_spell_2_cooldown()

func adjust_spawn_position(spawn_pos: Vector2):
	var space_state = get_world_2d().direct_space_state
	var query_parameters = PhysicsPointQueryParameters2D.new()
	
	var attempts = 0
	while attempts < 32:
		query_parameters.position = spawn_pos
		var collision = space_state.intersect_point(query_parameters)
		
		if collision.is_empty():
			return spawn_pos
		
		var direction = (spawn_pos - position).normalized()
		spawn_pos += direction
		
		attempts += 1
	return Vector2.INF # If adjustment failed

func get_animation_lengths():
	attack_1_length = anim_player.get_animation("attack_right_1").length
	attack_2_length = anim_player.get_animation("attack_right_2").length

func _on_combo_timer_timeout() -> void:
	player.attack_index = 1.0
	player.can_attack = true

func stop_systems():
	$ComboTimer.stop()
	$AttackTimer.stop()
	if !player.is_slowed and !player.is_rooted:
		player.speed = base_speed
	stop_spells()
