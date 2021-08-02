class_name CreationPopup
extends ConfirmationDialog

var _name := ''
var _main_dock: PopochiuDock setget set_main_dock

onready var _input: LineEdit = find_node('Input')
onready var _error_feedback: Label = find_node('ErrorFeedback')
onready var _info: RichTextLabel = find_node('Info')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	register_text_enter(_input)
	
	connect('confirmed', self, 'create')
	connect('popup_hide', self, '_clear_fields')
	_input.connect('text_changed', self, '_update_name')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func set_main_dock(node: PopochiuDock) -> void:
	_main_dock = node


func create() -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _update_name(new_text: String) -> void:
	if _error_feedback.visible:
		_error_feedback.hide()
	
	var casted_name := PoolStringArray()
	for idx in new_text.length():
		if idx == 0:
			casted_name.append(new_text[idx].to_upper())
		else:
			casted_name.append(new_text[idx])

	_name = casted_name.join('').strip_edges()


func _clear_fields() -> void:
	_input.clear()
	_error_feedback.hide()

	_info.clear()
