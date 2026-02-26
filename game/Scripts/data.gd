extends Node

class_name GameData

# Raw player state data which is the basic facts about what the player is doing
var player_position: Vector2 = Vector2.ZERO
var player_velocity: Vector2 = Vector2.ZERO
var player_on_floor: bool = false
var player_is_big: bool = false

var time: float = 0.0  
var lives: int = 0      
var points: int = 0    
var coins: int = 0      
var enemies_killed: int = 0  
var number_of_jumps: int = 0  
var death_by_fall: int = 0    
var horizontal_speed: float = 0.0  
var pct: float = 0.0  # Points * Coins / Time
var ekj: float = 0.0  # Enemies killed / Number of jumps
var score: float = 0.0 
var difficulty: String = "EASY"


func get_time() -> float:
	return time

func set_time(value: float) -> void:
	time = max(0.0, value)  # Ensure non-negative


func get_lives() -> int:
	return lives

func set_lives(value: int) -> void:
	lives = max(0, value)  # Ensure non-negative


func get_points() -> int:
	return points

func set_points(value: int) -> void:
	points = value  
	calculate_pct()  # Update PCT when points change


func get_coins() -> int:
	return coins

func set_coins(value: int) -> void:
	coins = max(0, value)  # Ensure non-negative
	calculate_pct()  # Update PCT when coins change


func get_enemies_killed() -> int:
	return enemies_killed

func set_enemies_killed(value: int) -> void:
	enemies_killed = max(0, value)  # Ensure non-negative
	calculate_ekj()  # Update EKJ when enemies_killed changes


func get_number_of_jumps() -> int:
	return number_of_jumps

func set_number_of_jumps(value: int) -> void:
	number_of_jumps = max(0, value)  # Ensure non-negative
	calculate_ekj()  # Update EKJ when number_of_jumps changes

func get_death_by_fall() -> int:
	return death_by_fall

func set_death_by_fall(value: int) -> void:
	death_by_fall = max(0, value)  # Ensure non-negative

func get_horizontal_speed() -> float:
	return horizontal_speed

func set_horizontal_speed(value: float) -> void:
	horizontal_speed = max(0.0, value)  # Ensure non-negative

func get_pct() -> float:
	return pct

func set_pct(value: float) -> void:
	pct = max(0.0, value)  # Ensure non-negative

func calculate_pct() -> void:
	if time > 0.0:  # Avoid division by zero
		pct = (points * coins) / time
	else:
		pct = 0.0

func get_ekj() -> float:
	return ekj

func set_ekj(value: float) -> void:
	ekj = max(0.0, value)  # Ensure non-negative

func calculate_ekj() -> void:
	if number_of_jumps > 0:  # Avoid division by zero
		ekj = enemies_killed / float(number_of_jumps)
	else:
		ekj = 0.0

func get_score() -> float:
	return score

func set_score(value: float) -> void:
	score = clamp(value, 0, 100)  # Ensure between 0 and 100 inclusive

func get_difficulty() -> String:
	return difficulty

func set_difficulty(value: String) -> void:
	difficulty = value
	
		
func set_player_state(position: Vector2, velocity: Vector2, on_floor: bool, is_big: bool) -> void:
	self.player_position = position
	self.player_velocity = velocity
	self.player_on_floor = on_floor
	self.player_is_big = is_big
	
func calculate_difficulty():
	if score <= 25:
		difficulty = "EASY"
	if 25 < score and score <= 50:
		difficulty = "NORMAL"
	if 50 < score and score <= 75:
		difficulty = "HARD"	
	if 75 < score and score <= 100:
		difficulty = "EXTREME"
				
func to_dict() -> Dictionary:
	return {
		"player_position": player_position,
		"player_velocity": player_velocity,
		"player_on_floor": player_on_floor,
		"player_is_big": player_is_big,
		"time": time,
		"lives": lives,
		"points": points,
		"coins": coins,
		"enemies_killed": enemies_killed,
		"number_of_jumps": number_of_jumps,
		"death_by_fall": death_by_fall,
		"horizontal_speed": horizontal_speed,
		"pct": pct,
		"ekj": ekj,
		"score": score,
		"difficulty":difficulty
	}
