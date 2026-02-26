extends Area2D

class_name Fireball

@onready var ray_cast_2d = $RayCast2D

@export var horizontal_speed = 200
@export var vertical_speed = 100
var amplitude = 20
var is_moving_up = false

var direction
var vertical_movement_start_position
var start_x
const MAX_DISTANCE: float = 144.0

func _ready():
	start_x = position.x

func _process(delta):
	position.x += delta * horizontal_speed * direction
	if ray_cast_2d.is_colliding():
		is_moving_up = true
		vertical_movement_start_position = position
		
	if is_moving_up:
		position.y -= vertical_speed * delta
		if vertical_movement_start_position.y - amplitude >= position.y:
			is_moving_up = false
			
	if !is_moving_up:
		position.y += delta * vertical_speed

	var distance_traveled = abs(position.x - start_x)
	if distance_traveled >= MAX_DISTANCE:
		queue_free()

func _on_area_entered(area):
	if area is Enemy:
		area.die_from_hit()
	queue_free()
