extends Node

var return_point: Vector2
var player_mode: Player.PlayerMode
var points: int
var coins: int
var lives: int
var current_level_index: int = 0
static var level_start_time = 0
static var previous_level_end_time = 0
var level_times = {}

var enemy_spawn_rate: float = 1.0
var player_max_health: int = 4
var platform_speed: float = 1.0

func reset():
	points = 0
	coins = 0
	lives = 5
	current_level_index = 0
