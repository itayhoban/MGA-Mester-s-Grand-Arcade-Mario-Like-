extends CanvasLayer

class_name UI

@onready var center_container = $MarginContainer/CenterContainer

@onready var score_label = $MarginContainer/HBoxContainer/scoreLabel
@onready var coins_label = $MarginContainer/HBoxContainer/coinsLabel
@onready var lives_label = $MarginContainer/HBoxContainer/livesLabel

func set_score(points: int):
	score_label.text = "SCORE: %d" % points
	
func set_coins(coins: int):
	coins_label.text = "COINS: %d" % coins
	
func set_lives(lives: int):
	lives_label.text = "LIVES: %d" % lives
	
func on_finish():
	center_container.visible = true
	
func hide_finish_panel():
	$MarginContainer/CenterContainer.visible = false
