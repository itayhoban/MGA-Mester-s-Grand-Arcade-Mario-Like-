extends Control

signal quiz_finished

const ANSWER_BUTTON_SCENE = preload("res://Scenes/answer_button.tscn")

@onready var canvas_layer = $TriviaQuiz
@onready var category_label = $TriviaQuiz/MarginContainer/VBoxContainer/CategoryLabel
@onready var question_label = $TriviaQuiz/MarginContainer/VBoxContainer/QuestionLabel
@onready var answer_container = $TriviaQuiz/MarginContainer/VBoxContainer/AnswerContainer

var all_trivia_data: Array
var current_category_data: Dictionary
var current_question_index: int = 0
var answer_buttons: Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	_load_trivia_data()
	_prepare_answer_buttons()
	canvas_layer.visible = false # Hide the quiz until it's startes

func _load_trivia_data():
	var file = FileAccess.open("res://history_questions_by_category.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var parse_result = JSON.parse_string(json_string)
		if parse_result:
			all_trivia_data = parse_result
		else:
			print("Error parsing trivia JSON")

func _prepare_answer_buttons():
	for i in range(0, 4):
		var button = ANSWER_BUTTON_SCENE.instantiate()
		button.choice_selected.connect(_on_answer_selected)
		answer_container.add_child(button)
		answer_buttons.append(button)

func start_quiz():
	current_question_index = 0
	current_category_data = all_trivia_data.pick_random()
	category_label.text = current_category_data["category"]
	_display_next_question()
	canvas_layer.visible = true

func _display_next_question():
	if current_question_index >= current_category_data["questions"].size():
		_end_quiz()
		return

	var question_data = current_category_data["questions"][current_question_index]

	# Update the UI
	question_label.text = question_data["question"]
	for i in range(0, 4):
		var button = answer_buttons[i] as AnswerButton
		button.reset_state()
		button.set_display(question_data["choices"][i], i)

func _on_answer_selected(button_index: int):
	# Prevent further clicks while showing the result
	for button in answer_buttons:
		button.disabled = true

	var question_data = current_category_data["questions"][current_question_index]
	var correct_index = question_data["correctIndex"]
	var selected_button = answer_buttons[button_index] as AnswerButton

	if button_index == correct_index:
		selected_button.update_state(true)
	else:
		selected_button.update_state(false)
		var correct_button = answer_buttons[correct_index] as AnswerButton
		correct_button.reveal_as_correct()

	# Wait for 2 seconds before showing the next question
	await get_tree().create_timer(1.0).timeout

	current_question_index += 1
	_display_next_question()

func _end_quiz():
	canvas_layer.visible = false
	print("Category finished!")
	emit_signal("quiz_finished")
