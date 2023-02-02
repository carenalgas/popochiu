tool
extends Panel

# Node references
onready var font_title : Label = $Layout/FontName
onready var font_sample : Label = $Layout/FontSample
onready var background_panel : Panel = $BackgroundPanel

# Public properties
var font_name : String = "" setget set_font_name
var type_name : String = "" setget set_type_name
var sample_text : String = "Sample Text" setget set_sample_text
var selected : bool = false setget set_selected

signal item_selected()

func _ready() -> void:
	font_title.text = font_name
	font_sample.text = sample_text
	
	_update_sample_font()
	_update_background()

func _gui_input(event : InputEvent) -> void:
	if (event is InputEventMouseButton && event.button_index == BUTTON_LEFT && !event.is_pressed() && !event.is_echo()):
		set_selected(true)
		emit_signal("item_selected")

# Properties
func set_font_name(value : String) -> void:
	font_name = value
	_update_sample_font()
	
	if (is_inside_tree()):
		font_title.text = font_name

func set_type_name(value : String) -> void:
	type_name = value
	_update_sample_font()

func set_sample_text(value : String) -> void:
	sample_text = "Sample Text" if value.empty() else value
	
	if (is_inside_tree()):
		font_sample.text = sample_text

func set_selected(value : bool) -> void:
	if (selected == value):
		return
	selected = value
	
	_update_background()
	
	if (selected):
		var items = get_tree().get_nodes_in_group("ETE_FontItems")
		for item in items:
			if (item == self):
				continue
			
			item.selected = false

# Helpers
func _update_sample_font() -> void:
	if (font_name.empty() || type_name.empty() || !is_inside_tree()):
		return
	
	var sample_font = get_font(font_name, type_name)
	font_sample.add_font_override("font", sample_font)
	font_sample.add_color_override("font_color", get_color("accent_color", "Editor"))
	
	rect_min_size.y = 40.0 + sample_font.get_height()

func _update_background() -> void:
	if (!is_inside_tree()):
		return
	
	var label_stylebox = get_stylebox("panel", "Panel").duplicate() as StyleBoxFlat
	if (selected):
		label_stylebox.bg_color = get_color("highlight_color", "Editor")
	else:
		label_stylebox.bg_color = Color(0, 0, 0, 0)
	background_panel.add_stylebox_override("panel", label_stylebox)
