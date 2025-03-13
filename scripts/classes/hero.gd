extends Node2D

@onready var player: CharacterBody2D
@onready var anim_player: AnimationPlayer

var attack_1_length: float = 0.4
var attack_2_length: float = 0.4
var attack_3_length: float = 0.5
var combo_timer = 1.5
@export var dash_speed: float = 0
var last_dash_speed: float = 0
var type = "melee"

func _ready() -> void:
	player = get_parent()
	anim_player = $AnimationPlayer
	get_animation_lengths()
	$SpellHitbox.player_id = player.player_id

func _process(delta: float) -> void:
	check_property_changes()
	rotate_weapon()
	if player.in_spell_2:
		if player.is_multiplayer_authority():
			StageManager.set_target.rpc(player.player_id,get_global_mouse_position())
		spell_2_follow.rpc()

func rotate_weapon():
	$Weapon.look_at(player.get_node("Target").global_position)
	$Hitbox.look_at(player.get_node("Target").global_position)

@rpc("any_peer","call_local")
func attack(index: float):
	player.is_attacking = true
	$ComboTimer.stop()
	$ComboTimer.wait_time = combo_timer
	$Hitbox.damage = player.damage
	$Weapon.show()
	match index:
		1.0:
			player.dash_duration = attack_1_length - 0.2
			$ComboTimer.start()
			use_attack_timer(attack_1_length)
			$Weapon.play("attack_1")
		2.0:
			player.dash_duration = attack_2_length - 0.2
			$ComboTimer.start()
			use_attack_timer(attack_2_length)
			$Weapon.play("attack_2")
		3.0:
			player.dash_duration = attack_3_length - 0.3
			player.damage = player.base_damage * 2
			$Hitbox.damage = player.damage
			use_attack_timer(attack_3_length)
			$Weapon.play("attack_3")

@rpc("any_peer","call_local")
func spell_1(): # 50 dmg, 2 sec duration
	player.in_spell_1 = true
	player.dash_duration = 0.5
	$SpellHitbox.damage = 50
	$SpellHitbox.player_id = player.player_id
	$Spell1Timer.wait_time = 2.0
	$Spell1Timer.start()

func _on_spell_1_timer_timeout():
	if player.in_spell_1:
		start_spell_1_cooldown()
	else:
		player.spell_1_ready = true

func start_spell_1_cooldown(): # 5 sec CD
	var duration = 5.0
	player.in_spell_1 = false
	$Spell1Timer.wait_time = duration
	$Spell1Timer.start()
	player.queue_spell_cooldown(duration, 1)

@rpc("any_peer","call_local")
func spell_2(): # 20 dmg, 4 sec duration
	player.in_spell_2 = true
	$SpellHitbox.damage = 20
	$SpellFX.show()
	$SpellFX.play("spell2start")
	await $SpellFX.animation_finished
	$SpellFX.play("spell2")
	$Spell2Timer.wait_time = 4.0
	$Spell2Timer.start()

@rpc("any_peer","call_local")
func spell_2_follow():
	$SpellHitbox.global_position = \
	$SpellHitbox.global_position.lerp(StageManager.get_target(player.player_id),0.01)
	$SpellFX.global_position = \
	$SpellFX.global_position.lerp(StageManager.get_target(player.player_id),0.01)

func _on_spell_2_timer_timeout():
	if player.in_spell_2:
		$SpellFX.stop()
		$SpellFX.hide()
		$SpellHitbox.position = Vector2(0,0)
		$SpellFX.position = Vector2(0,0)
		start_spell_2_cooldown()
	else:
		player.spell_2_ready = true

func start_spell_2_cooldown(): # 10 sec CD
	player.in_spell_2 = false
	var duration = 6.0
	$Spell2Timer.wait_time = duration
	$Spell2Timer.start()
	player.queue_spell_cooldown(duration, 2)

func use_attack_timer(time: float):
	$AttackTimer.wait_time = time
	$AttackTimer.start()
	await $AttackTimer.timeout
	player.is_attacking = false
	$Weapon.hide()
	$AttackTimer.wait_time = 0.01
	$AttackTimer.start()
	await $AttackTimer.timeout
	if player.attack_index == 3:
		player.attack_index = 1 # Reset after 3rd attack
		$ComboTimer.wait_time = 0.7
		$ComboTimer.start()
	else:
		player.attack_index += 1.0
		player.can_attack = true

func get_animation_lengths():
	attack_1_length = anim_player.get_animation("attack_right_1").length
	attack_2_length = anim_player.get_animation("attack_right_2").length
	attack_3_length = anim_player.get_animation("attack_right_3").length

func _on_combo_timer_timeout() -> void:
	player.attack_index = 1.0
	player.damage = player.base_damage
	player.can_attack = true

func stop_systems():
	$ComboTimer.stop()
	$AttackTimer.stop()
	stop_spells()

func check_property_changes():
	if last_dash_speed != dash_speed:
		player.get_node("Target").global_position = player.get_global_mouse_position()
		player.dash_speed = dash_speed
		player.tween_dash_value()
		last_dash_speed = dash_speed
	else:
		pass

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
