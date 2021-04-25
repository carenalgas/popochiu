class_name DisplayBox
extends Label

signal shown
signal hidden


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	text = ''
	
	G.connect('show_box_requested', self, '_show_box')
	
	hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _show_box(msg := '') -> void:
	text = msg

	if msg:
		show()
		emit_signal('shown')
	else:
		hide()
		emit_signal('hidden')
