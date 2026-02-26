extends AnimatedSprite2D

class_name PlayerAnimatedSprite

var frame_count: int = 0
var is_jumping: bool = false
var last_direction: int = 1  # Default to right
var game_data: GameData = GameData.new()

func _ready() -> void:
	# Attempt to get GameData instance (assuming it's an autoload or parent node)
	if game_data == null:
		push_warning("GameData not found! Stats tracking disabled.")
	set_process(true)  # Ensure process is active for state updates

func _process(_delta: float) -> void:
	var parent: Player = get_parent() as Player
	if not is_instance_valid(parent):
		return
	if not is_playing() and not parent.is_on_floor() and parent.velocity.y < 0:
		is_jumping = true
	elif parent.is_on_floor():
		is_jumping = false
		if game_data:
			game_data.set_number_of_jumps(game_data.get_number_of_jumps() + 1)

func trigger_animation(velocity: Vector2, direction: int, player_mode: Player.PlayerMode) -> void:
	if not is_instance_valid(get_parent()):
		return

	var animation_prefix: String = Player.PlayerMode.keys()[player_mode].to_snake_case()
	var parent: Player = get_parent() as Player

	if not parent.is_on_floor():
		if velocity.y < 0 and not is_jumping:
			is_jumping = true
			if game_data:
				game_data.set_number_of_jumps(game_data.get_number_of_jumps() + 1)
		play("%s_jump" % animation_prefix)
	elif sign(velocity.x) != sign(direction) and abs(velocity.x) > 10 and direction != 0:
		# Sliding animation when moving against intended direction
		play("%s_slide" % animation_prefix)
		scale.x = direction
	else:
		# Update sprite direction
		if direction != 0:
			last_direction = direction
			scale.x = direction
		elif velocity.x == 0 and scale.x != last_direction:
			scale.x = last_direction  # Maintain last direction when idle

		# Run or idle based on velocity
		if abs(velocity.x) > 10:
			if game_data:
				game_data.set_horizontal_speed(abs(velocity.x))
			play("%s_run" % animation_prefix)
		else:
			play("%s_idle" % animation_prefix)

func _on_animation_finished() -> void:
	var parent: Player = get_parent() as Player
	if not is_instance_valid(parent):
		return

	if animation == "small_to_big":
		reset_player_properties()
		if parent.player_mode == Player.PlayerMode.SMALL:
			parent.player_mode = Player.PlayerMode.BIG
		elif parent.player_mode == Player.PlayerMode.BIG:
			parent.player_mode = Player.PlayerMode.SMALL

	elif animation in ["small_to_shooting", "big_to_shooting"]:
		reset_player_properties()
		parent.player_mode = Player.PlayerMode.SHOOTING

	elif animation == "shoot":
		parent.set_physics_process(true)

	elif animation == "death":
		if game_data:
			game_data.set_death_by_fall(game_data.get_death_by_fall() + 1)
		parent.die()  # Trigger death logic in Player.gd

func reset_player_properties() -> void:
	offset = Vector2.ZERO
	var parent: Player = get_parent() as Player
	if is_instance_valid(parent):
		parent.set_physics_process(true)
		parent.set_collision_layer_value(1, true)
	frame_count = 0

func _on_frame_changed() -> void:
	if animation in ["small_to_big", "small_to_shooting", "big_to_shooting"]:
		var parent: Player = get_parent() as Player
		if not is_instance_valid(parent):
			return
		frame_count += 1
		var offset_y: float = 0
		if frame_count % 2 == 1:
			offset_y = 0 if parent.player_mode == Player.PlayerMode.BIG else -8
		else:
			offset_y = 8 if parent.player_mode == Player.PlayerMode.BIG else 0
		offset = Vector2(0, offset_y)

func on_pole(player_mode: Player.PlayerMode) -> void:
	var animation_prefix: String = Player.PlayerMode.keys()[player_mode].to_snake_case()
	play("%s_pole" % animation_prefix)
