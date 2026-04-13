extends Node2D

@export var fireball_scene: PackedScene

@onready var player: CharacterBody2D
@onready var anim_player: AnimationPlayer
@onready var game_node: Node
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
	game_node = $/root/Main/Game
	
	get_animation_lengths()

func _process(delta: float) -> void:
	pass

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
	mouse_pos = StageManager.get_target(player.player_id)
	
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
		game_node.spawn(fireball)
		fireball.position = $Marker2D.global_position
		fireball.direction = fireball.position.direction_to(mouse_pos)
		fireball.rotation = fireball.direction.angle()
		fireball.velocity = fireball.direction * fireball.speed
		fireball.damage = player.damage
		fireball.player_id = player.player_id
	else:
		# Calculate angle offset
		var start_angle = -60 #-60 / 2
		var angle_step = 60 #60 / 4
		for i in range(6):
			var fireball = fireball_scene.instantiate()
			game_node.spawn(fireball)
			
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
			
			await get_tree().create_timer(0.002).timeout

func use_attack_timer(time: float):
	$AttackTimer.wait_time = time
	$AttackTimer.start()
	await $AttackTimer.timeout
	player.is_attacking = false
	if player.attack_index == 3.0:
		player.attack_index = 1.0 # Reset after 3rd attack
		$ComboTimer.wait_time = 0.7
		$ComboTimer.start()
	else:
		player.attack_index += 1.0
		player.can_attack = true
	if !player.is_slowed and !player.is_rooted:
		player.speed = base_speed
	if dodge_timer.is_stopped(): player.can_dodge = true

@rpc("any_peer","call_local")
func spell_1(): # 25 dmg, 3 sec duration
	player.in_spell_1 = true
	await get_tree().create_timer(0.3).timeout
	for i in range(12):
			var fireball = fireball_scene.instantiate()
			add_child(fireball)
			
			# Set projectile position and direction
			fireball.is_spell_1 = true
			fireball.direction = Vector2(1,0) # Initial direction
			fireball.center_point = Vector2(position.x, position.y - 22)
			fireball.damage = player.damage
			fireball.player_id = player.player_id
			await get_tree().create_timer(0.08).timeout
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
func spell_2(): # 75 dmg, 1.3 sec duration
	player.in_spell_2 = true
	$SpellFX.global_position = StageManager.get_target(player.player_id)
	$SpellHitbox.global_position = StageManager.get_target(player.player_id)
	$SpellFX.show()
	$SpellFX.play("spell1")
	$Spell2Timer.wait_time = 1.3
	$Spell2Timer.start()

func _on_spell_2_timer_timeout() -> void:
	if player.in_spell_2:
		$SpellFX.stop()
		$SpellFX.hide()
		$SpellHitbox/CollisionShape2D.disabled = true
		$SpellHitbox.position = Vector2(0,0)
		$SpellFX.position = Vector2(0,0)
		start_spell_2_cooldown()
	else:
		player.spell_2_ready = true

func start_spell_2_cooldown(): # 5 sec cd
	player.in_spell_2 = false
	var duration = 5.0
	$Spell2Timer.wait_time = duration
	$Spell2Timer.start()
	player.queue_spell_cooldown(duration, 2)

func stop_spells():
	$SpellFX.stop()
	$SpellFX.hide()
	if player.in_spell_1:
		$Spell1Timer.stop()
		start_spell_1_cooldown()
	if player.in_spell_2:
		$Spell2Timer.stop()
		start_spell_2_cooldown()
	$SpellHitbox.position = Vector2(0,0)
	$SpellFX.position = Vector2(0,0)

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
	if !player.is_slowed and !player.is_rooted:
		player.speed = base_speed
	stop_spells()
