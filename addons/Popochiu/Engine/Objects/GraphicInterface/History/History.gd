extends Control

onready var _lines_list: VBoxContainer = find_node('LinesList')
onready var _dialog_line_path := filename.get_base_dir() + '/DialogLine.tscn'
onready var _interaction_line_path := filename.get_base_dir() + '/InteractionLine.tscn'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	# Conectarse a eventos de los hijos
	$WindowDialog.connect('popup_hide', self, '_destroy_history')
	# Conectarse a eventos de singletons
	G.connect('history_opened', self, '_show_history')
	
	hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _show_history() -> void:
	for data in E.history:
		var lbl: Label
		
		if data.has('character'):
			lbl = load(_dialog_line_path).instance()
			lbl.text = '%s: %s' % [data.character, data.text]
		else:
			lbl = load(_interaction_line_path).instance()
			lbl.text = '(%s)' % data.action
	
		_lines_list.add_child(lbl)
	
#	popup(Rect2(8, 16, 304, 160))
	$WindowDialog.popup_centered(Vector2(240.0, 120.0))
	
	G.emit_signal('blocked', { blocking = false })
	Cursor.set_cursor(Cursor.Type.USE)
	Cursor.block()
	
	show()


func _destroy_history() -> void:
	for c in _lines_list.get_children():
		(c as Label).queue_free()
	
	G.done()
	Cursor.unlock()
	
	hide()
