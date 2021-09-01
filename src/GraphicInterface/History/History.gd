class_name History
extends WindowDialog

const DIALOG_LINE := 'res://src/GraphicInterface/History/DialogLine.tscn'
const INTERACTION_LINE := 'res://src/GraphicInterface/History/InteractionLine.tscn'

onready var _lines_list: VBoxContainer = find_node('LinesList')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	# Conectarse a eventos de los hijos
	connect('popup_hide', self, '_destroy_history')
	# Conectarse a eventos de singletons
	G.connect('history_opened', self, '_show_history')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _show_history() -> void:
	for data in E.history:
		var lbl: Label
		
		if data.has('character'):
			lbl = preload(DIALOG_LINE).instance()
			lbl.text = '%s: %s' % [data.character, data.text]
		else:
			lbl = preload(INTERACTION_LINE).instance()
			lbl.text = '(%s)' % data.action
	
		_lines_list.add_child(lbl)
	
#	popup(Rect2(8, 16, 304, 160))
	popup_centered(Vector2(240.0, 120.0))
	
	G.emit_signal('blocked', { blocking = false })
	Cursor.set_cursor(Cursor.Type.USE)
	Cursor.block()


func _destroy_history() -> void:
	for c in _lines_list.get_children():
		(c as Label).queue_free()
	
	G.done()
	Cursor.unlock()
