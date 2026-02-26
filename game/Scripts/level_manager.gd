extends Node
class_name LevelManager

var inactivity_timer: Timer
var flash_timer: Timer
var player_active : bool = true

var player_stats = {
	"points" : 0,
	"coins" : 0,
	"lives" : 5
}

var game_state = {
	"audio_stream" : null,
	"audio_player" : null
}

# Variables for data collection
var game_data_array: Array = [] 
var data_timer: Timer  # Timer for collecting data every 1 seconds
static var current_time: float = 0.0
static var enemies_killed: int = 0  
static var number_of_jumps: int = 0  
static var death_by_fall: int = 0
static var pct: float = 0.0 # Points * Coins / Time
static var ekj: float = 0.0 # Enemies killed / Number of jumps
static var score: float = 0.0
static var difficulty: = "EASY"
var current_mode: int = Player.PlayerMode.SMALL  # Track player's mode (small, big, shooting)
var mode_start_time: float = 0.0  # Time when current mode started
var total_small_time: float = 0.0  # Total time spent in small mode

var pending_reload: bool = false # State variable for managing scene reload

@export var ui: UI
@export var player: Player
@export var trivia_ui: Control

var levels = [
	"res://Scenes/main.tscn", 
	"res://Scenes/level2.tscn", 
	"res://Scenes/level3.tscn",
	"res://Scenes/level4.tscn",
	"res://Scenes/level5.tscn",
	"res://Scenes/level6.tscn",
	"res://Scenes/level7.tscn",
	"res://Scenes/level8.tscn",
	"res://Scenes/level9.tscn",
	"res://Scenes/level10.tscn",
	"res://Scenes/level11.tscn",
	"res://Scenes/level12.tscn",
	"res://Scenes/main_menu.tscn"
]

var http_request: HTTPRequest
static var data_deleted := false

func _ready():					
	delete_game_data_on_start()
	
	if not player:
		return
	
	if not ui:
		push_error("Error: UI node not assigned in Inspector for LevelManager!
		 Please drag the UI node into the 'ui' slot in the Inspector.")
	
	if player.has_signal("castle_entered"):
		player.castle_entered.connect(_on_castle_entered)
	else:
		push_warning("Player node missing 'castle_entered' signal")

	if player.has_signal("points_scored"):
		player.points_scored.connect(on_points_scored)
	else:
		push_warning("Player node missing 'points_scored' signal")
		
	if player.has_signal("died"):
		player.died.connect(on_player_died)

	if SceneData.points > 0:
		player_stats["points"] = SceneData.points
		ui.set_score(player_stats["points"])
		
	if SceneData.coins > 0:
		player_stats["coins"] = SceneData.coins
		ui.set_coins(player_stats["coins"])
		
	if SceneData.lives > 0:
		player_stats["lives"] = SceneData.lives
		ui.set_lives(player_stats["lives"])
		
	_initialize_music()
	
	# Start timing for the current level only if the player didn't die in the level
	if SceneData.level_start_time == 0:
		SceneData.level_start_time = Time.get_ticks_msec()
		
	# Setup inactivity timer
	inactivity_timer = Timer.new()
	inactivity_timer.wait_time = 30.0
	inactivity_timer.one_shot = false # Makes the timer repeat after the player again not active
	inactivity_timer.timeout.connect(_on_inactivity_timer_timeout)
	add_child(inactivity_timer)
	inactivity_timer.start()
	
	# Setup data timer
	data_timer = Timer.new()	
	data_timer.wait_time = 1.0
	data_timer.timeout.connect(collect_game_data)
	add_child(data_timer)
	data_timer.start()
	
	# Setup flash timer
	flash_timer = Timer.new()
	flash_timer.wait_time = 3.0
	flash_timer.one_shot = false
	flash_timer.timeout.connect(_trigger_flash)
	add_child(flash_timer)
	
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_http_request_request_completed)

func on_points_scored(points_scored: int):
	player_stats["points"] += points_scored
	if not ui:
		push_error("Error:ui is null – assign it in Inspector!")
	ui.set_score(player_stats["points"])

func on_coin_collected():
	player_stats["coins"] += 1
	ui.set_coins(player_stats["coins"])

func _input(_event):
	# Reset inactivity timer on any input
	if inactivity_timer != null:
		inactivity_timer.start()
		
	if not player_active:
		player_active = true
		if flash_timer and flash_timer.is_stopped() == false:
			flash_timer.stop()

func _on_inactivity_timer_timeout():
	player_active = false
	if flash_timer and flash_timer.is_stopped():
		flash_timer.start()
	
func _trigger_flash():
	# Create Canvas layer to ensure the flash is drawn on top of everything
	var flash_canvas = CanvasLayer.new()
	flash_canvas.layer = 10
	
	# Create the ColorRect to act as a flash effect
	var flash_rect = ColorRect.new()
	flash_rect.color = Color(1,1,1,0)
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT) # Make it cover the screen
	
	flash_canvas.add_child(flash_rect)
	add_child(flash_canvas)
	
	# Create a tween to animate the flash
	var tween = get_tree().create_tween()
	tween.tween_property(flash_rect, "color", Color(1,1,1,0.6), 0.1)
	tween.tween_property(flash_rect, "color", Color(1,1,1,0), 0.3)
	tween.tween_callback(flash_canvas.queue_free) # Remove the flash canvas when the tween is finished
	
	
func _on_castle_entered() -> void:
	SceneData.previous_level_end_time = SceneData.previous_level_end_time + current_time
	
	if data_timer and data_timer.is_stopped() == false:
		data_timer.stop()
		print("stop timer")
			
	if not ui:
		push_error("UI reference missing!")
		return

	ui.on_finish()

	await get_tree().create_timer(2.0, true).timeout
	
	# Hide the "You won" panel before trivia
	ui.hide_finish_panel()
	
	# Calculate the time spent of the level
	var level_end_time = Time.get_ticks_msec()
	var level_time = level_end_time - SceneData.level_start_time
	var level_name = "Level %d" % (SceneData.current_level_index + 1)
	SceneData.level_times[level_name] = level_time
	SceneData.level_start_time = level_end_time
	
	if trivia_ui:
		print("I have trivia ui")
		trivia_ui.quiz_finished.connect(_advance_to_next_level)
		trivia_ui.start_quiz()
	else:
		print("Trivia ui not assigned - skipping quiz.")
		_advance_to_next_level()

func _advance_to_next_level():
	if data_timer and data_timer.is_stopped():
		data_timer.start()
		print("timer start")	
	
	SceneData.current_level_index = SceneData.current_level_index + 1
	SceneData.level_start_time = Time.get_ticks_msec() 

	if SceneData.current_level_index < levels.size(): 
		SceneData.points = player_stats["points"]
		SceneData.coins = player_stats["coins"]
		get_tree().change_scene_to_file(levels[SceneData.current_level_index])
	else:
		print("All levels completed!")
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _initialize_music():
	game_state["audio_stream"] = null
	var current_scene_name = get_tree().current_scene.name
	if current_scene_name == "Main":
		game_state["audio_stream"] = load("res://Sounds/levels_sound/E1V1.mp3")
	elif current_scene_name == "Underground":
		game_state["audio_stream"] = load("res://Sounds/levels_sound/Underground sound.mp3")
	elif current_scene_name == "Gameover":
		game_state["audio_stream"] = load("res://Assets/sounds/Game_Over_Sound.mp3")
	elif current_scene_name.begins_with("Level"):
		var level_number = current_scene_name.trim_prefix("Level").to_int()
		var music_index = (level_number - 1) % 10 + 1  # Maps level to 1-10 range
		match music_index:
			1:
				game_state["audio_stream"] = load("res://Sounds/levels_sound/E1V1.mp3")
			2:
				game_state["audio_stream"] = load("res://Sounds/levels_sound/E2V1.mp3")
			3:
				game_state["audio_stream"] = load("res://Sounds/levels_sound/E3V1.mp3")
			4:
				game_state["audio_stream"] = load("res://Sounds/levels_sound/E4V1.mp3")
			5:
				game_state["audio_stream"] = load("res://Sounds/levels_sound/E5V1.mp3")
			6:
				game_state["audio_stream"] = load("res://Sounds/levels_sound/E6V1.mp3")
			7:
				game_state["audio_stream"] = load("res://Sounds/levels_sound/E7V0.mp3")
			8:
				game_state["audio_stream"] = load("res://Sounds/levels_sound/E8V1.mp3")
			9:
				game_state["audio_stream"] = load("res://Sounds/levels_sound/E9V1.mp3")
			10:
				game_state["audio_stream"] = load("res://Sounds/levels_sound/E10V1.mp3")
	else:
		game_state["audio_stream"] = load("res://Sounds/levels_sound/AviciiLevels.mp3")

	if game_state["audio_stream"]:
		game_state["audio_player"] = AudioStreamPlayer.new()
		game_state["audio_player"].stream = game_state["audio_stream"]
		if current_scene_name != "Underground":
			game_state["audio_player"].volume_db = -8  # Set volume to 40% (approximately -8 dB)
		add_child(game_state["audio_player"])
		game_state["audio_player"].play()
	else:
		push_warning("Failed to load background music for scene: " + current_scene_name)
		
func on_player_died():
	player_stats["lives"] -= 1
	ui.set_lives(player_stats["lives"])
	var tree = get_tree()
	# Wait to let animation/sound play before changing scene
	await get_tree().create_timer(2.0, true).timeout

	if player_stats["lives"] <= 0:
		SceneData.reset()
		call_deferred("change_scene_safe", "res://Scenes/game_over.tscn")
	else:
		SceneData.points = player_stats["points"]
		SceneData.coins = player_stats["coins"]
		SceneData.lives = player_stats["lives"]
		tree.call_group("level_manager", "reload_scene_safe")
		
func change_scene_safe(scene_path: String):
	get_tree().change_scene_to_file(scene_path)
	
func reload_scene_safe():
	if not is_inside_tree():
		push_error("Cannot reload scene: node is no longer inside the scene tree.")
		return

	var tree = get_tree()
	if tree.current_scene:
		tree.reload_current_scene()
	else:
		push_error("Cannot reload scene: current_scene is null.")
	
func _print_level_times():
	print("\n All levels completed! Level completion times:")
	for level in SceneData.level_times.keys():
		var ms = SceneData.level_times[level]
		var seconds = ms / 1000.0
		print(" - %s: %.2f seconds" % [level, seconds])	

func on_player_died_with_cause(cause: String):
		if cause == "fall":
			death_by_fall += 1

func _setup_player_signals():
	if not player:
		return
	if player.has_signal("castle_entered"):
		player.castle_entered.connect(_on_castle_entered)
	else:
		push_warning("Player node missing 'castle_entered' signal")

	if player.has_signal("points_scored"):
		player.points_scored.connect(on_points_scored)
	else:
		push_warning("Player node missing 'points_scored' signal")
		
	if player.has_signal("died"):
		player.died.connect(on_player_died)

func on_enemy_killed():
		enemies_killed += 1
		
func on_player_jump():
		number_of_jumps += 1

func on_player_mode_changed(new_mode: int):
		current_time = Time.get_ticks_msec()
		var time_spent = (current_time - mode_start_time) / 1000.0
		if current_mode == Player.PlayerMode.SMALL:
				total_small_time += time_spent
		mode_start_time = current_time
		current_mode = new_mode

func collect_game_data():
		if not is_instance_valid(player):
				return  
		var data = GameData.new()
		current_time = SceneData.previous_level_end_time + (Time.get_ticks_msec() - SceneData.level_start_time) / 1000.0
		#var current_time = (Time.get_ticks_msec() - SceneData.level_start_time) / 1000.0
		
		pct = player_stats["points"] * player_stats["coins"] / (int(current_time) + 0.00000001)
		pct = round(pct * 1000) / 1000.0 
		ekj = enemies_killed / (number_of_jumps + 0.00000001)
		ekj = round(ekj * 1000) / 1000.0
		
		score = player_score_raw()
		
		# Basic game state
		data.set_time(current_time)
		data.set_lives(player_stats["lives"])
		data.set_points(player_stats["points"])
		data.set_coins(player_stats["coins"])
		data.set_enemies_killed(enemies_killed)
		data.set_number_of_jumps(number_of_jumps)
		data.set_pct(pct)
		data.set_ekj(ekj)
		data.set_score(score)
		data.calculate_difficulty()
		data.set_death_by_fall(death_by_fall)
		data.set_horizontal_speed(abs(player.velocity.x))
		
		# Player state
		data.set_player_state(player.global_position,
		player.velocity,
		player.is_on_floor(),
		player.player_mode != Player.PlayerMode.SMALL
		)
		
		# Store the data
		game_data_array.append(data)
		
		send_game_data_to_server(data)
		
func _on_node_added(node: Node):
		# Check if the added node is a Player
		if node is Player and node != player:
				player = node
				_setup_player_signals()
				
				# Update mode and timing for data collection
				current_mode = player.player_mode
				mode_start_time = Time.get_ticks_msec()
				
				# Restart the timer now that we have a valid player
				if not data_timer.is_stopped():
						data_timer.stop()
				data_timer.start()
		
		# Check if the added node is a UI
		print("Node added:", node.name, "Type:", node.get_class())
		if node is UI and node != ui:
				ui = node
				# Update UI with current stats
				ui.set_score(player_stats["points"])
				ui.set_coins(player_stats["coins"])
				ui.set_lives(player_stats["lives"])

func apply_dynamic_difficulty():
		if game_data_array.size() == 0:
				return
		var latest_data: GameData = game_data_array[-1]
		match latest_data.difficulty:
				"EASY":
						SceneData.enemy_spawn_rate = 0.5
						SceneData.player_max_health = 5
						SceneData.platform_speed = 1.0
				"NORMAL":
						SceneData.enemy_spawn_rate = 1.0
						SceneData.player_max_health = 4
						SceneData.platform_speed = 1.2
				"HARD":
						SceneData.enemy_spawn_rate = 1.5
						SceneData.player_max_health = 3
						SceneData.platform_speed = 1.5
				"EXTREME":
						SceneData.enemy_spawn_rate = 2.0
						SceneData.player_max_health = 2
						SceneData.platform_speed = 1.8

func send_game_data_to_server(data: GameData):
	var json = JSON.stringify(data.to_dict())
	var headers = ["Content-Type: application/json"]
	var url = "http://localhost:3000/data" 

	var request_status = http_request.request(url, headers, HTTPClient.METHOD_POST, json)
	if request_status != OK:
		push_error("Failed to send game data: %s" % request_status)
		
func fetch_game_data_from_server():
	var url = "http://localhost:3000/data"
	var request_status = http_request.request(url, [], HTTPClient.METHOD_GET)

	if request_status != OK:
		push_error("Failed to fetch game data: %s" % request_status)	
		
func _on_http_request_request_completed(_result: int, response_code: int, _headers: Array, body: PackedByteArray):
	if response_code == 200 or response_code == 201:
		var text: String = body.get_string_from_utf8()
		var json: Variant = JSON.parse_string(text)
		
		if typeof(json) == TYPE_DICTIONARY:
			apply_difficulty_from_server_data(json)
		else:
			push_error("Unexpected response format: expected a dictionary.")
	else:
		push_error("Server returned error code: %d" % response_code)
		
func apply_difficulty_from_server_data(json):
	if not json.has("difficulty"):
		push_warning("Received server data missing 'difficulty' field.")
		return

	difficulty = json["difficulty"]
	match difficulty:
		"EASY":
			SceneData.enemy_spawn_rate = 0.5
			SceneData.player_max_health = 5
			SceneData.platform_speed = 1.0
		"NORMAL":
			SceneData.enemy_spawn_rate = 1.0
			SceneData.player_max_health = 4
			SceneData.platform_speed = 1.2
		"HARD":
			SceneData.enemy_spawn_rate = 1.5
			SceneData.player_max_health = 3
			SceneData.platform_speed = 1.5
		"EXTREME":
			SceneData.enemy_spawn_rate = 2.0
			SceneData.player_max_health = 2
			SceneData.platform_speed = 1.8
		# default case
		_:
			push_warning("Unknown difficulty level received from server: " + str(difficulty))

func player_score_raw() -> int:
	score = (
		0.02 * pct +        
		15.0 * ekj +        
		0.00001 * pow(pct, 2) - 
		0.01 * pct * ekj + 
		5.0 * pow(ekj, 2)
	)
	
	score = score * 3.2
	score = round(score)
	
	var new_score = score
		
	if score <= -855:
		new_score = 0
	
	if -855 < score and score < 0:
		new_score = -new_score
		new_score = 7.25 - log(new_score)
	
	if score == 0:
		new_score = 7  
		
	if 1 <= score and score <= 7:
		new_score = new_score + log(new_score)
	
	if 100 <= score and score < 1250:
		new_score = new_score / 125
		new_score = log(new_score) / log(10) 
		new_score = 100 - pow(0.5, new_score)
	
	if score >= 1250:
		new_score = 100
		
	return int(round(new_score))
	

func delete_game_data_on_start():
	print("delete_game_data_on_start called on instance: ", self, " data_deleted: ", data_deleted)	
	if data_deleted:
		return
		
	data_deleted = true
	
	print(data_deleted)
	
	var delete_request := HTTPRequest.new()
	add_child(delete_request)
	
	delete_request.request_completed.connect(_on_delete_request_completed)
	var url = "http://localhost:3000/data"
	var request_status = delete_request.request(url, [], HTTPClient.METHOD_DELETE)
	if request_status != OK:
		push_error("Failed to send delete request: %s" % request_status)
	else:
		print("Delete request sent successfully")

func _on_delete_request_completed(_result, response_code, _headers, _body):
	if response_code == 200:
		print("Data deleted successfully on start.")
	else:
		push_error("Failed to delete data at start. Server response code: %d" % response_code)
