extends Node2D

@onready var credits_label1 = $TextEdit1
@onready var credits_label2 = $TextEdit2
@onready var credits_label3 = $TextEdit3
@onready var credits_label4 = $TextEdit4
@onready var credits_label5 = $TextEdit5
@onready var credits_label6 = $TextEdit6
@onready var credits_label7 = $TextEdit7
@onready var credits_label8 = $TextEdit8
@onready var credits_label9 = $TextEdit9
@onready var credits_label10 = $TextEdit10
@onready var credits_label11 = $TextEdit11

var speed = 58.0  # Scrolling speed (pixels per second)
var labels = []
var delay = 7.0  # Delay between inserting new labels in seconds
var elapsed_time = 0.0
var active_labels = []
var timer = 0.0  # Timer for 6 seconds

func _ready():
	# Populate the labels array
	labels = [
		credits_label1, credits_label2, credits_label3, credits_label4,
		credits_label5, credits_label6, credits_label7, credits_label8,
		credits_label9, credits_label10, credits_label11
	]
	
	# Set initial positions above the screen for all labels, but only show the first one initially
	for label in labels:
		if label:
			label.position.y = -label.size.y
			label.visible = false
	if credits_label1:
		credits_label1.visible = true
		
	var sound = AudioStreamPlayer.new()
	sound.stream = preload("res://Sounds/levels_sound/George Michael - Careless Whisper Instrumental.mp3")
	get_tree().current_scene.add_child(sound)
	sound.play()

func _process(delta):
	elapsed_time += delta
	
	# Insert new labels at intervals
	if len(active_labels) < len(labels) and elapsed_time >= delay:
		var next_index = len(active_labels)
		var next_label = labels[next_index]
		if next_label and not next_label in active_labels:
			next_label.visible = true
			active_labels.append(next_label)
			elapsed_time = 0.0  # Reset timer after inserting a new label
	
	# Move all active labels downward
	for label in active_labels:
		if label:
			label.position.y += speed * delta
			
			# Remove label when it goes off-screen
			#if label.position.y > get_viewport_rect().size.y:
				#label.queue_free()
				#active_labels.erase(label)
	
	# Start timer after the first label appears
	if len(active_labels) > 0:
		timer += delta
	
	# Transition to main menu after 60 seconds
	if timer >= 81.5:
		if get_tree():
			var menu_scene = load("res://Scenes/main_menu.tscn")
			if menu_scene:
				get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
			else:
				push_error("Failed to load main_menu.tscn. Please check the file path and ensure it is imported.")
