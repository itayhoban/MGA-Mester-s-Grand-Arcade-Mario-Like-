extends Button

class_name AnswerButton

signal choice_selected(button_index)

const COLOR_NORMAL = Color("2e2e2e")
const COLOR_CORRECT = Color("2a6e3b") # Green
const COLOR_INCORRECT = Color("872e2e") # Red
const COLOR_REVEAL = Color("ffffff") # White background
const FONT_COLOR_REVEAL = Color("000000") # Black font

var button_index: int
var clicked: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	focus_mode = FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	self.pressed.connect(_on_button_pressed)
	
func _on_button_pressed():
	if clicked:
		return
	clicked = true
	emit_signal("choice_selected", button_index)
	
func set_display(text_display: String, index: int):
	self.text = text_display
	button_index = index
	
func reset_state():
	disabled = false
	clicked = false
	_apply_color(COLOR_NORMAL)
	add_theme_color_override("font_color", Color.WHITE)

func update_state(is_correct: bool):
	if is_correct:
			_apply_color(COLOR_CORRECT)
	else:
		_apply_color(COLOR_INCORRECT)
	
func reveal_as_correct():
	_apply_color_with_border(COLOR_NORMAL, COLOR_REVEAL)
	add_theme_color_override("font_color", FONT_COLOR_REVEAL)

func _apply_color(color: Color):
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = color
	stylebox.set_corner_radius_all(12)
	_apply_stylebox_to_all(stylebox)

func _apply_color_with_border(bg_color: Color, border_color: Color):
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = bg_color
	stylebox.border_color = border_color
	stylebox.set_border_width_all(2)
	_apply_stylebox_to_all(stylebox)
	
func _apply_stylebox_to_all(stylebox: StyleBox):
	add_theme_stylebox_override("normal", stylebox)
	add_theme_stylebox_override("hover", stylebox)
	add_theme_stylebox_override("pressed", stylebox)
	add_theme_stylebox_override("disabled", stylebox)
	add_theme_stylebox_override("focus", stylebox) 
