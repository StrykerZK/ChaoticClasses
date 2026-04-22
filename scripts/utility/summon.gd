extends CharacterBody2D

class_name Summon

@export var speed: float = 250.0
@export var attack_range: float = 30.0
@export var health: float = 60.0
@export var damage: float = 25.0
var player_id: int

var nearest_player: CharacterBody2D = null
var can_attack = true
var is_attacking = false
var is_spawning = true
var is_dead = false
var attack_timer: Timer = null
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var hp_bar: ProgressBar = $HPBar

var current_world: Node2D

func _ready():
	current_world = get_tree().get_first_node_in_group("world")

func _physics_process(delta: float):
	hp_bar.value = health
	
	nearest_player = get_nearest_player()
	
	if nearest_player and !is_dead and !is_spawning:
		var distance_to_player = position.distance_to(nearest_player.global_position)
		
		if distance_to_player <= attack_range and can_attack:
			attack()
		else:
			if !is_attacking and !is_dead:
				move_towards_player(delta)
	else:
		velocity = Vector2.ZERO
		move_and_slide()

func get_nearest_player():
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return null
	
	var nearest_player_found: CharacterBody2D = null
	var nearest_distance = INF
	
	for player in players:
		if player.player_id == player_id:
			continue
		
		var player_position = Vector2(player.global_position.x, player.global_position.y - 22)
		var distance = global_position.distance_to(player_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_player_found = player
	
	return nearest_player_found

func move_towards_player(delta):
	if nearest_player:
		var player_position = Vector2(nearest_player.global_position.x, nearest_player.global_position.y - 22)
		navigation_agent.target_position = player_position
		var next_position = navigation_agent.get_next_path_position()
		
		if not (is_nan(next_position.x) or is_nan(next_position.y)):
			var direction = (next_position - global_position).normalized()
			var new_velocity = direction * speed
			
			if navigation_agent.avoidance_enabled:
				navigation_agent.set_velocity(new_velocity)
			else:
				velocity = new_velocity
			
			move_and_slide()
		else:
			velocity = Vector2.ZERO
			move_and_slide()

func attack():
	pass

func take_damage(incoming_dmg: float):
	if incoming_dmg <= 0:
		return
	
	health -= incoming_dmg
	
	if health <= 0:
		die()

func die():
	queue_free()
