extends CharacterBody2D

class_name Player

signal points_scored(points: int)
signal castle_entered
signal died

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum PlayerMode {
	SMALL,
	BIG,
	SHOOTING
}

const PIPE_ENTER_THRESHOLD = 10

#On ready
const POINTS_LABEL_SCENE = preload("res://Scenes/points_label.tscn")
const SMALL_MARIO_COLLISION_SHAPE = preload("res://Resources/CollisionShapes/small_mario_collision_shape.tres")
const BIG_MARIO_COLLISION_SHAPE = preload("res://Resources/CollisionShapes/big_mario_collision_shape.tres")
const FIREBALL_SCENE = preload("res://Scenes/fireball.tscn")

#References
@onready var animated_sprite_2d = $AnimatedSprite2D as PlayerAnimatedSprite
@onready var area_2d = $Area2D
@onready var area_collision_shape = $Area2D/AreaCollisionShape
@onready var body_collision_shape = $BodyCollisionShape
@onready var shooting_point = $shootingPoint
@onready var slide_down_finished_position
@onready var land_down_marker
var last_player_y: float
var time_since_last_check: float = 0.0

@export_group("Locomotion")
@export var run_speed_damping = 0.5
@export var speed = 200.0
@export var jump_velocity = -350
@export_group("")

@export_group("Stomping enemies")
@export var min_stomp_degree = 35
@export var max_stomp_degree = 145
@export var stomp_y_velocity = -150
@export_group("")

@export_group("Camera sync")
@onready var camera_sync: Camera2D = get_node("../Camera2D")

@export var should_camera_sync: bool = true
@export_group("")

@export var castle_path: PathFollow2D
var player_mode = PlayerMode.SMALL
var current_action: String = "idle"

# Player state flags
var is_dead = false
var is_on_path = false

func _ready() -> void:
	if SceneData.return_point != null && SceneData.return_point != Vector2.ZERO:
		var return_marker = get_node_or_null("../pipeReturnPoint")
		if return_marker:
			global_position = return_marker.global_position
		SceneData.return_point = Vector2.ZERO
	
	# Optional nodes - assign if they exist, otherwise leave as null
	slide_down_finished_position = get_node_or_null("../slide_down_finished_position")
	land_down_marker = get_node_or_null("../landDownMarker")
	
	# Auto-find castle_path if not assigned in Inspector
	if castle_path == null:
		var pf = get_parent().get_node_or_null("Path2D/PathFollow2D")
		if pf:
			castle_path = pf
		else:
			# Log a warning instead of an error, as this is expected in some scenes
			push_warning("Player.castle_path is null and no Path2D/PathFollow2D found in scene: %s" % get_tree().current_scene.name)

func _physics_process(delta):
	
	var camera_left_bound = camera_sync.global_position.x - camera_sync.get_viewport_rect().size.x / 2 / camera_sync.zoom.x
	
	#Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	#You can't come back after you continue
	if global_position.x < camera_left_bound + 8 && sign(velocity.x) == -1:
		velocity = Vector2.ZERO
		return

	# Handle crouch (only for BIG or SHOOTING modes)
	var temp
	if (player_mode != PlayerMode.SMALL):
			temp = player_mode
	if (player_mode == PlayerMode.BIG or player_mode == PlayerMode.SHOOTING) and Input.is_action_pressed("down"):
		# Play small idle animation
		while Input.is_action_pressed("down"):
			set_physics_process(false)
			animated_sprite_2d.play("small_idle2")
			area_collision_shape.set_deferred("shape", SMALL_MARIO_COLLISION_SHAPE)
			body_collision_shape.set_deferred("shape", SMALL_MARIO_COLLISION_SHAPE)
			await get_tree().create_timer(0.1).timeout
			set_physics_process(true)
			player_mode = PlayerMode.SMALL
			await get_tree().create_timer(0.1).timeout
	else:
		# Ensure collision shape is big when not crouching
		if player_mode == PlayerMode.BIG or player_mode == PlayerMode.SHOOTING:
			player_mode = temp
			area_collision_shape.set_deferred("shape", BIG_MARIO_COLLISION_SHAPE)
			body_collision_shape.set_deferred("shape", BIG_MARIO_COLLISION_SHAPE)
	if (temp != null):
		player_mode = temp
	
	#Handle jumps
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		var level_manager = get_tree().get_first_node_in_group("level_manager")
		if level_manager:
			level_manager.on_player_jump()
		
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5
		
		
	#Handle axis movement
	var direction = 0
	var horizontal_input = Input.get_axis("left", "right")
	current_action = "idle"  # Reset to idle each frame
	
	if horizontal_input > 0:
		direction = 1
		current_action = "move_right"
	if horizontal_input < 0:
		direction = -1
		current_action = "move_left"
	if Input.is_action_just_pressed("jump") and is_on_floor():
		current_action = "jump"
	if Input.is_action_just_pressed("shoot") and player_mode == PlayerMode.SHOOTING:
		current_action = "shoot"
	
	if direction:
		velocity.x = lerpf(velocity.x, speed * direction, run_speed_damping * delta)
	else:	
		velocity.x = move_toward(velocity.x, 0, speed * delta)
	
	if Input.is_action_just_pressed("shoot") && player_mode == PlayerMode.SHOOTING:
		shoot()
	else:
		animated_sprite_2d.trigger_animation(velocity, direction, player_mode)
	
	var collision = get_last_slide_collision()
	if collision != null:
		handle_movement_collision(collision)
	
	move_and_slide()

func _process(delta):
	camera_sync.global_position.x = global_position.x
	
	var camera_y = camera_sync.global_position.y
	var target_y = global_position.y - 58
	
	time_since_last_check += delta
	var vertical_change = abs(global_position.y - last_player_y)
	
	var lerp_speed = 0.375
	
	# Check if player fell more than 100 pixels in less than 1 second
	if vertical_change >= 122 and time_since_last_check <= 1.0:
		lerp_speed = 1.74
	else:
		lerp_speed = 0.355
		
	# If timer exceeded 1 second, reset and store current Y
	if time_since_last_check >= 1.0:
		time_since_last_check = 0.0
		last_player_y = global_position.y
	
	if global_position.y - last_player_y >= 112:
		camera_sync.global_position.y = global_position.y - 58
	else:
		camera_sync.global_position.y = lerp(camera_y, target_y, delta * lerp_speed)
		
	# only advance the path if we both flagged is_on_path AND castle_path is valid
	if is_on_path:
		if castle_path:
			castle_path.progress += delta * speed / 2
			if castle_path.progress_ratio > 0.97:
				is_on_path = false
				land_down()
		else:
			# fail-safe: cancel path mode
			is_on_path = false
			push_error("Cannot advance castle_path because it's null!")


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area is Enemy:
		handle_enemy_collision(area)
	if area is Shroom:
		handle_shroom_collision(area)
		area.queue_free()
	if area is ShootingFlower:
		handle_flower_collision()
		area.queue_free()
		
func handle_enemy_collision(enemy: Enemy):
	if enemy == null or is_dead:
		return

	if enemy is Koopa:
		var koopa = enemy as Koopa

		if koopa.in_a_shell:
			if koopa.is_sliding:
				# sliding shell → hurt player AND reverse shell direction
				if player_mode == PlayerMode.SMALL:
					die()
				elif player_mode == PlayerMode.BIG:
					big_tosmall()
				elif player_mode == PlayerMode.SHOOTING:
					shooting_tobig()
				koopa.reverse_direction()
			else:
				# stationary shell → kick it to start sliding
				koopa.on_stomp(global_position)
			return

		# Normal Koopa (not in shell)
		var stomp_angle = rad_to_deg(position.angle_to_point(koopa.position))
		if stomp_angle > min_stomp_degree and stomp_angle < max_stomp_degree:
			koopa.on_stomp(global_position)
			on_enemy_stomped()
			spawn_points_label(koopa)
		else:
			if player_mode == PlayerMode.SMALL:
				die()
			elif player_mode == PlayerMode.BIG:
				big_tosmall()
			elif player_mode == PlayerMode.SHOOTING:
				shooting_tobig()
		return

	# Other enemies
	var angle = rad_to_deg(position.angle_to_point(enemy.position))
	if angle > min_stomp_degree and angle < max_stomp_degree:
		enemy.die()
		on_enemy_stomped()
		spawn_points_label(enemy)
	else:
		if player_mode == PlayerMode.SMALL:
			die()
		elif player_mode == PlayerMode.BIG:
			big_tosmall()
		elif player_mode == PlayerMode.SHOOTING:
			shooting_tobig()

func handle_shroom_collision(_area: Node2D):
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	if level_manager:
		level_manager.on_points_scored(75)
	var sound = AudioStreamPlayer.new()
	sound.stream = preload("res://sounds/environmental_sound/mashrom.mp3")
	get_tree().current_scene.add_child(sound)
	sound.play()

	if player_mode == PlayerMode.SHOOTING:
		speed = 200.0
		jump_velocity = -375
		return
	else:
		player_mode = PlayerMode.BIG
		set_physics_process(false)
		area_collision_shape.set_deferred("shape", BIG_MARIO_COLLISION_SHAPE)
		body_collision_shape.set_deferred("shape", BIG_MARIO_COLLISION_SHAPE)
		await get_tree().create_timer(0.2).timeout
		set_physics_process(true)
		speed = 220.0
		speed = 220.0
		jump_velocity = -350
		# Snap to ground to prevent floating
		move_and_collide(Vector2(0, 10))  # Small downward movement to force ground contact

func handle_flower_collision():
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	if level_manager:
		level_manager.on_points_scored(125)
	position.y -= 10
	if player_mode == PlayerMode.SHOOTING:
		jump_velocity = -375
		return
	set_physics_process(false)
	if player_mode == PlayerMode.SMALL:
		animated_sprite_2d.play("small_to_shooting")
	else:
		animated_sprite_2d.play("big_to_shooting")
	area_collision_shape.set_deferred("shape", BIG_MARIO_COLLISION_SHAPE)
	body_collision_shape.set_deferred("shape", BIG_MARIO_COLLISION_SHAPE)
	player_mode = PlayerMode.SHOOTING
	level_manager = get_tree().get_first_node_in_group("level_manager")
	if level_manager:
		level_manager.on_player_mode_changed(PlayerMode.SHOOTING)
	jump_velocity = -375
	
func spawn_points_label(enemy):
	var points_label = POINTS_LABEL_SCENE.instantiate()
	points_label.position = enemy.position + Vector2(-20, -20)
	get_tree().root.add_child(points_label)
	points_scored.emit(100)
	
		
func on_enemy_stomped():
	velocity.y = stomp_y_velocity
	
func die(cause: String = ""):
	if player_mode == PlayerMode.SMALL:
		is_dead = true
		animated_sprite_2d.play("death")
		var level_manager = get_tree().get_first_node_in_group("level_manager")
		if level_manager:
			level_manager.on_points_scored(-1)
			if cause == "fall":
				print("you should count me as fall")
				level_manager.on_player_died_with_cause("fall")
			else:
				level_manager.on_player_died_with_cause("enemy")
			
		area_2d.set_collision_mask_value(3, false)
		set_collision_layer_value(1, false)
		
		set_physics_process(false)
				
		var death_tween = get_tree().create_tween()
		death_tween.tween_property(self, "position", position + Vector2(0, -48), 0.5)
		death_tween.chain().tween_property(self, "position", position + Vector2(0, 256), 1)
		var sound = AudioStreamPlayer.new()
		sound.stream = preload("res://Assets/sounds/Mario Death.mp3")
		get_tree().current_scene.add_child(sound)
		sound.play()
		emit_signal("died")
		
	else:
		player_mode -= 1
		if player_mode == PlayerMode.BIG:
			big_tosmall()
		if player_mode == PlayerMode.SHOOTING:
			shooting_tobig()
			
	
func handle_movement_collision(collision: KinematicCollision2D):
	if collision.get_collider() is Block:
		var collision_angle = rad_to_deg(collision.get_angle())
		if roundf(collision_angle) == 180:
			(collision.get_collider() as Block).bump(player_mode)
	
	if collision.get_collider() is Pipe:
		var collision_angle = rad_to_deg(collision.get_angle())
		if roundf(collision_angle) == 0 && Input.is_action_just_pressed("down") && absf(collision.get_collider().position.x - position.x) < PIPE_ENTER_THRESHOLD && collision.get_collider().is_traversable:
			print("GO DOWN")
			handle_pipe_collision()

func set_collision_shapes(is_small: bool):
	var collision_shape = SMALL_MARIO_COLLISION_SHAPE if is_small else BIG_MARIO_COLLISION_SHAPE
	area_collision_shape.set_deferred("shape", collision_shape)
	body_collision_shape.set_deferred("shape", collision_shape)

func shoot():
	animated_sprite_2d.play("shoot")
	set_physics_process(false)
	
	var fireball = FIREBALL_SCENE.instantiate()
	fireball.direction = sign(animated_sprite_2d.scale.x)
	fireball.global_position = shooting_point.global_position
	get_tree().root.add_child(fireball)
	
func handle_pipe_collision():
	set_physics_process(false)
	var pipe_tween = get_tree().create_tween()
	pipe_tween.tween_property(self, "position", position + Vector2(0, 32), 1)
	pipe_tween.tween_callback(switch_to_underground)
	
func switch_to_underground() -> void:
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	if not level_manager:
		push_error("LevelManager not found! Cannot save game state before switching to underground.")
		return
	
	# Save game state using LevelManager's variables
	SceneData.player_mode = player_mode
	SceneData.coins = level_manager.player_stats["coins"]
	SceneData.points = level_manager.player_stats["points"]
	
	# Ensure physics is disabled to prevent collision issues during transition
	set_physics_process(false)
	
	# Change scene
	var error = get_tree().change_scene_to_file("res://Scenes/underground.tscn")
	if error != OK:
		push_error("Failed to switch to underground.tscn: Error code %s" % error)

func save_game_state():
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	if level_manager:
		SceneData.player_mode = player_mode
		SceneData.coins = level_manager.player_stats["coins"]
		SceneData.points = level_manager.player_stats["points"]

func handle_pipe_connector_entrance_collision():
	print("PIPE CONNECTOR ENTERED")
	
	set_physics_process(false)	
	var pipe_tween = get_tree().create_tween()
	pipe_tween.tween_property(self, "position", position + Vector2(32, 0), 1)
	pipe_tween.tween_callback(switch_to_main)

# Return from underground phase
func switch_to_main():
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	SceneData.player_mode = player_mode
	SceneData.coins = level_manager.player_stats["coins"]
	SceneData.points = level_manager.player_stats["points"]
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func on_pole_hit():
	set_physics_process(false)
	velocity = Vector2.ZERO
	if is_on_path:
		return
		
	animated_sprite_2d.on_pole(player_mode)
	
	var slide_down_tween = get_tree().create_tween()
	var slide_down_position = slide_down_finished_position.position
	slide_down_tween.tween_property(self, "position", slide_down_position, 2)
	slide_down_tween.tween_callback(slide_down_finished)

func slide_down_finished() -> void:
	var animation_prefix = Player.PlayerMode.keys()[player_mode].to_snake_case()
	if castle_path:
		is_on_path = true
		animated_sprite_2d.play("%s_jump" % animation_prefix)
		reparent(castle_path)
	else:
		push_warning("Cannot follow castle path: castle_path is null!")

func land_down() -> void:
	if land_down_marker:
		var distance_to_marker = (land_down_marker.position - position).y
		var land_tween = get_tree().create_tween()
		land_tween.tween_property(self, "position", position + Vector2(0, distance_to_marker - get_half_sprite_size()), 0.5)
		land_tween.tween_callback(go_to_castle)
	else:
		push_warning("Cannot land down: land_down_marker is null!")

func go_to_castle():
	var sound = AudioStreamPlayer.new()
	sound.stream = preload("res://Assets/sounds/Level Complete.mp3")
	get_tree().current_scene.add_child(sound)
	sound.play()
	var animation_prefix = Player.PlayerMode.keys()[player_mode].to_snake_case()
	animated_sprite_2d.play("%s_run" %animation_prefix)
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	if level_manager:
		level_manager.on_points_scored(250)
	var run_to_castle_tween = get_tree().create_tween()
	run_to_castle_tween.tween_property(self, "position", position + Vector2(75, 0), 0.5)
	run_to_castle_tween.tween_callback(finish)
	
func finish():
	queue_free()
	castle_entered.emit()	
	
func get_half_sprite_size():
	return 8 if player_mode == PlayerMode.SMALL else 16

func shooting_tobig():
	print("shooting to big")
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	if level_manager:
		level_manager.on_points_scored(-5)
	var sound = AudioStreamPlayer.new()
	sound.stream = preload("res://Assets/sounds/hurt.wav")
	get_tree().current_scene.add_child(sound)
	sound.play()
	set_physics_process(false)
	animated_sprite_2d.play("shooting_to_big")
	await get_tree().create_timer(0.25).timeout
	area_collision_shape.set_deferred("shape", BIG_MARIO_COLLISION_SHAPE)
	body_collision_shape.set_deferred("shape", BIG_MARIO_COLLISION_SHAPE)
	await get_tree().create_timer(0.25).timeout
	set_physics_process(true)
	player_mode = PlayerMode.BIG
	level_manager = get_tree().get_first_node_in_group("level_manager")
	if level_manager:
		level_manager.on_player_mode_changed(PlayerMode.BIG)
	speed = 220.0
	jump_velocity = -350
	await get_tree().create_timer(0.3).timeout
	
func big_tosmall():
	print("big to small")
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	if level_manager:
		level_manager.on_points_scored(-10)
	var sound = AudioStreamPlayer.new()
	sound.stream = preload("res://Assets/sounds/hurt.wav")
	get_tree().current_scene.add_child(sound)
	sound.play()
	set_physics_process(false)
	animated_sprite_2d.play("big_to_small")
	await get_tree().create_timer(0.25).timeout
	area_collision_shape.set_deferred("shape", SMALL_MARIO_COLLISION_SHAPE)
	body_collision_shape.set_deferred("shape", SMALL_MARIO_COLLISION_SHAPE)
	await get_tree().create_timer(0.25).timeout
	set_physics_process(true)
	player_mode = PlayerMode.SMALL
	level_manager = get_tree().get_first_node_in_group("level_manager")
	if level_manager:
		level_manager.on_player_mode_changed(PlayerMode.SMALL)
	speed = 200.0
	jump_velocity = -350
	#position.y -= 10
	await get_tree().create_timer(0.3).timeout
	
func is_above_floor() -> bool:
	if is_on_floor():
		return false  # Mario is directly on the floor, not above it
	# Use a raycast to check for a small gap below
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 10), 1 << 0)  # Layer 0 for floor
	var result = space_state.intersect_ray(query)
	if result:
		var distance_to_floor = abs(result.position.y - global_position.y)
		return distance_to_floor < 10  # Consider Mario "above" if within 10 pixels of the floor
	return false
