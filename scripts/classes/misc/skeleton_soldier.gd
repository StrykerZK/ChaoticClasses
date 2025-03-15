extends Summon

func _ready() -> void:
	health = 60.0
	damage = 40.0
	$Hitbox.damage = damage
	attack_range = 40.0
	speed = 0.0
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
		$Hitbox/CollisionShape2D.position.x = abs($Hitbox/CollisionShape2D.position.x)
	elif velocity.x < 0:
		$AnimatedSprite2D.flip_h = true
		$Hitbox/CollisionShape2D.position.x = -abs($Hitbox/CollisionShape2D.position.x)

func attack():
	can_attack = false
	is_attacking = true
	$AnimatedSprite2D.play("attack")
	await get_tree().create_timer(0.2).timeout
	$Hitbox.monitoring = true
	await $AnimatedSprite2D.animation_finished
	is_attacking = false
	$Hitbox.set_deferred("monitoring",false)
	$AttackTimer.start()

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
	$Hitbox/CollisionShape2D.disabled = true
	$Hurtbox/CollisionShape2D.disabled = true

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
