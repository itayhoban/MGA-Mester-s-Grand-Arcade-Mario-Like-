extends Enemy

class_name Koopa

var in_a_shell = false
var is_sliding = false  

const KOOPA_SHELL_COLLISION_SHAPE_POSITION = Vector2(0, 5)
const KOOPA_FULL_COLLISION_SHAPE = preload("res://Resources/CollisionShapes/koopa_full_collision_shape.tres")
const KOOPA_SHELL_COLLISION_SHAPE = preload("res://Resources/CollisionShapes/koopa_shell_collision_shape.tres")
@onready var collision_shape_2d = $CollisionShape2D
var reverse = false

@export var slide_speed = 200

func _ready():
	collision_shape_2d.shape = KOOPA_FULL_COLLISION_SHAPE

func die():
	if !in_a_shell:
		super.die()
	var sound = AudioStreamPlayer.new()
	sound.stream = preload("res://Assets/sounds/Koopa Die sound.mp3")
	get_tree().current_scene.add_child(sound)
	sound.play()
	collision_shape_2d.set_deferred("shape", KOOPA_SHELL_COLLISION_SHAPE)
	collision_shape_2d.set_deferred("position", KOOPA_SHELL_COLLISION_SHAPE_POSITION)
	in_a_shell = true
	is_sliding = false  # shell starts stationary

func on_stomp(player_position: Vector2):
	if !in_a_shell:
		# entering shell mode
		die()
	else:
		# already in shell → kick it to slide
		var movement_direction = 1 if player_position.x <= global_position.x else -1
		horizontal_speed = -movement_direction * slide_speed
		is_sliding = true
	set_collision_mask_value(1, false)
	set_collision_layer_value(3, false)
	set_collision_layer_value(4, true)

func reverse_direction():
	horizontal_speed = -horizontal_speed
	animated_sprite_2d.stop()
	if reverse == false:
		animated_sprite_2d.play("walk2")
		reverse = true
	elif reverse == true:
		animated_sprite_2d.play("walk")
		reverse = false

func _process(delta):
	super._process(delta)
	
	if in_a_shell and horizontal_speed != 0:
		if not animated_sprite_2d.is_playing() or animated_sprite_2d.animation != "dead_moving":
			animated_sprite_2d.play("dead_moving")
			var sound = AudioStreamPlayer.new()
			sound.stream = preload("res://Assets/sounds/koopa shell.mp3")
			get_tree().current_scene.add_child(sound)
			sound.play()
	elif in_a_shell and horizontal_speed == 0:
		animated_sprite_2d.stop()
