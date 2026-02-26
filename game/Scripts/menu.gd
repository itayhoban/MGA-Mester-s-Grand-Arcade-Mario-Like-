extends Node
class_name menu

var start_button = null
var redX_button = null
var quit_button = null
var credit_button = null

func _ready():
	start_button = get_node_or_null("Startbutton")
	redX_button = get_node_or_null("redx")
	quit_button = get_node_or_null("quit")
	credit_button = get_node_or_null("credit")
	# Connect button signals
	if start_button:
		start_button.connect("pressed", Callable(self, "_on_StartGame_pressed"))
	if redX_button:
		redX_button.connect("pressed", Callable(self, "_on_Quit_pressed"))
	if quit_button:
		quit_button.connect("pressed", Callable(self, "_on_Quit_pressed"))
	if credit_button:
		credit_button.connect("pressed", Callable(self, "_on_Credit_pressed"))
	var sound = AudioStreamPlayer.new()
	sound.stream = preload("res://Sounds/levels_sound/Mario Menu.mp3")
	get_tree().current_scene.add_child(sound)
	sound.play()
   
# Function to handle Quit button press (exit game, including red X)
func _on_Quit_pressed():
	get_tree().quit()

# Function to handle StartGame button press (start the game)
func _on_StartGame_pressed():
	# Reset the game data
	SceneData.points = 0
	SceneData.coins = 0
	SceneData.lives = 5
	SceneData.current_level_index = 0
	SceneData.level_times.clear()  # Reset level times
	   
# Transition to the first level
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

# Function to handle Credit button press (transition to a new scene)
func _on_Credit_pressed():
	# Transition to a new scene (to be implemented later)
	if get_tree():
		get_tree().change_scene_to_file("res://Scenes/credit.tscn")
	else:
		var new_tree = SceneTree.new()
		get_viewport().set_scene_tree(new_tree)
		new_tree.change_scene_to_file("res://Scenes/credit.tscn")
