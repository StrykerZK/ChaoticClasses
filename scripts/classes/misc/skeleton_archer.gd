extends Summon

@export var arrow_scene: PackedScene
var arrow_speed: float = 500.0

func _ready() -> void:
	super._ready()
	
	health = 40.0
	$HPBar.max_value = health
	damage = 30.0
	attack_range = 300.0
	speed = 0.0
	$Name.text = name
	$AnimatedSprite2D.play("spawn")
	await $AnimatedSprite2D.animation_finished
	is_spawning = false
	speed = 150.0
	$NavigationAgent2D.max_speed = speed

func _process(delta: float):
	if !is_spawning and !is_attacking and !is_dead:
		$AnimatedSprite2D.play("walk")
	
	if velocity.x > 0:
		$AnimatedSprite2D.flip_h = false
	elif velocity.x < 0:
		$AnimatedSprite2D.flip_h = true

func attack():
	can_attack = false
	is_attacking = true
	$AnimatedSprite2D.play("attack")
	await get_tree().create_timer(0.8).timeout
	if !is_dead:
		spawn_projectile()
	await $AnimatedSprite2D.animation_finished
	is_attacking = false
	$AttackTimer.start()

func spawn_projectile():
	var arrow = arrow_scene.instantiate()
	arrow.damage = damage
	arrow.player_id = player_id
	arrow.speed = arrow_speed
	arrow.position = global_position
	if is_instance_valid(nearest_player):
		arrow.direction = arrow.position.direction_to(nearest_player.global_position)
	arrow.rotation = arrow.direction.angle()
	arrow.velocity = arrow.direction * arrow.speed
	current_world.spawn_misc(arrow)

func die():
	is_dead = true
	velocity = Vector2.ZERO
	stop_collisions()
	$AnimatedSprite2D.play("die")
	await $AnimatedSprite2D.animation_finished
	queue_free()

func _on_attack_timer_timeout() -> void:
	can_attack = true

func stop_collisions():
	$CollisionShape2D.disabled = true
	$Hurtbox/CollisionShape2D.disabled = true

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
