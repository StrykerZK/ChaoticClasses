extends Node2D

@export var arrow_scene: PackedScene
@export var spell_1_scene: PackedScene
@export var spell_2_scene: PackedScene

@onready var player: CharacterBody2D
@onready var anim_player: AnimationPlayer
@onready var anim_tree: AnimationTree
@onready var main_node: Node
@onready var dodge_timer: Timer

var release_length: float = 0.2
var ready_length: float = 0.5
var charge_1_length: float = 0.4
var charge_2_length: float = 0.5
var charge_1_time = 1.0
var charge_2_time = 1.5
var can_shoot = false
var early_shot = false
var base_speed = 150
@export var dash_speed: float = 0
var last_dash_speed: float = 0
var type = "ranged"

var mouse_pos

func _ready() -> void:
	player = get_parent()
	dodge_timer = player.get_node("DodgeCooldownTimer")
	anim_player = $AnimationPlayer
	anim_tree = $AnimationTree
	base_speed = player.speed
	main_node = get_tree().root.get_node("Main")
	
	get_animation_lengths()
	
	mouse_pos = get_global_mouse_position()

func _process(delta: float) -> void:
	check_property_changes()
	if !player.is_paused and !player.is_dodging:
		if player.is_multiplayer_authority():
			handle_input()

func handle_input():
	if player.is_attacking and !player.is_paused:
		if Input.is_action_just_released("attack"):
			mouse_pos = get_global_mouse_position()
			StageManager.set_target.rpc(player.player_id,mouse_pos)
			shoot.rpc()

@rpc("any_peer","call_local")
func shoot():
	if can_shoot:
		spawn_projectile(player.attack_index)
	else:
		early_shot = true

@rpc("any_peer","call_local")
func attack(index: float):
	player.speed = player.speed * 0.2
	player.can_dodge = false
	can_shoot = false
	if !player.is_dodging:
		player.is_attacking = true
		$ChargeTimer.wait_time = charge_1_time - charge_1_length
		match index:
			1.0:
				use_attack_timer(ready_length)
				await $AttackTimer.timeout
				if early_shot == true:
					early_shot = false
					spawn_projectile(player.attack_index)
				else:
					can_shoot = true
					$ChargeTimer.start()

@rpc("any_peer","call_local")
func charge_projectile():
	match player.attack_index:
		1.0:
			if player.is_attacking:
				$ChargeTimer.wait_time = charge_2_time - charge_2_length
				player.attack_index += 0.5
				$ChargeAnimTimer.wait_time = charge_1_length
				$ChargeAnimTimer.start()
		2.0:
			if player.is_attacking:
				player.attack_index += 0.5
				$ChargeAnimTimer.wait_time = charge_2_length
				$ChargeAnimTimer.start()

func finish_charge():
	if player.is_attacking:
		match player.attack_index:
			1.5:
				player.attack_index += 0.5
				player.damage = player.base_damage * 2
				$ChargeTimer.start()
			2.5:
				player.attack_index += 0.5
				player.damage = player.base_damage * 4

func spawn_projectile(index: float):
	$ChargeTimer.stop()
	$ChargeAnimTimer.stop()
	player.speed = 0
	if player.attack_index == 1.5 or player.attack_index == 2.5:
		player.attack_index -= 0.5
	
	if player.player_id == StageManager.p1_id:
		mouse_pos = StageManager.p1_target
	else:
		mouse_pos = StageManager.p2_target
	
	var arrow = arrow_scene.instantiate()
	main_node.add_child(arrow)
	arrow.position = $Marker2D.global_position
	arrow.direction = arrow.position.direction_to(mouse_pos)
	arrow.rotation = arrow.direction.angle()
	arrow.velocity = arrow.direction * arrow.speed
	arrow.damage = player.damage
	arrow.player_id = player.player_id
	arrow.charge_arrow(index)
	
	can_shoot = false
	player.attack_index = 0.0
	use_attack_timer(release_length)
	await $AttackTimer.timeout
	player.is_attacking = false
	player.attack_index = 1.0
	player.damage = player.base_damage
	if !player.is_slowed and !player.is_rooted:
		player.speed = base_speed
	player.can_attack = true
	if dodge_timer.is_stopped(): player.can_dodge = true
	early_shot = false

func use_attack_timer(time: float):
	$AttackTimer.wait_time = time
	$AttackTimer.start()

@rpc("any_peer","call_local")
func spell_1(): # 30 dmg, 3 sec root, 5 sec cd
	player.in_spell_1 = true
	player.dash_duration = 1.0
	$Spell1Timer.wait_time = 1.2
	$Spell1Timer.start()
	var spell_1_instance = spell_1_scene.instantiate()
	spell_1_instance.position = player.global_position
	spell_1_instance.player_id = player.player_id
	await get_tree().create_timer(0.6).timeout
	main_node.add_child(spell_1_instance)

func _on_spell_1_timer_timeout():
	if player.in_spell_1:
		player.in_spell_1 = false
		$Spell1Timer.wait_time = 5.0
		$Spell1Timer.start()
	else:
		player.spell_1_ready = true

@rpc("any_peer","call_local")
func spell_2(): # 25 dmg, 4 sec duration, 8 sec cd
	player.in_spell_2 = true
	await get_tree().create_timer(1).timeout
	player.in_spell_2 = false
	var spell_2_instance = spell_2_scene.instantiate()
	spell_2_instance.player_id = player.player_id
	if player.player_id == StageManager.p1_id:
		spell_2_instance.position = StageManager.p1_target
	else:
		spell_2_instance.position = StageManager.p2_target
	main_node.add_child(spell_2_instance)
	$Spell2Timer.wait_time = 8
	$Spell2Timer.start()

func _on_spell_2_timer_timeout() -> void:
	player.spell_2_ready = true

func stop_spells():
	$Spell1Timer.stop()
	$Spell2Timer.stop()

func get_animation_lengths():
	release_length = anim_player.get_animation("release_right").length
	ready_length = anim_player.get_animation("ready_right").length
	charge_1_length = anim_player.get_animation("charge_1_right").length
	charge_2_length = anim_player.get_animation("charge_2_right").length

func stop_systems():
	$ChargeAnimTimer.stop()
	$ChargeTimer.stop()
	$AttackTimer.stop()
	if !player.is_slowed and !player.is_rooted:
		player.speed = base_speed

func check_property_changes():
	if last_dash_speed != dash_speed:
		player.dash_speed = dash_speed
		player.tween_dash_value()
		last_dash_speed = dash_speed
	else:
		pass
