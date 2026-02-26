extends Node

@onready var start_button = $startbutton
@onready var quit = $redx

func _ready():
	# Connect button signals
	if start_button:
		start_button.connect("pressed", Callable(self, "_on_StartAgain_pressed"))
	if quit:
		quit.connect("pressed", Callable(self, "_on_Quit_pressed"))
	var sound = AudioStreamPlayer.new()
	sound.stream = preload("res://Assets/sounds/Game_Over_Sound.mp3")
   

# Function to handle Quit button press (exit game, including red X)
func _on_Quit_pressed():
	if get_tree():
		get_tree().quit()

# Function to handle StartGame button press (start the game)
func _on_StartAgain_pressed():
	# Reset the game data
	SceneData.points = 0
	SceneData.coins = 0
	SceneData.lives = 5
	SceneData.current_level_index = 0
	SceneData.level_times.clear()  
	
	# Transition to the first level
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
