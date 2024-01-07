extends Control
# warning-ignore-all:return_value_discarded

const DIALOG_LINE := preload('components/dialog_line.tscn')
const INTERACTION_LINE := preload('components/interaction_line.tscn')

@onready var _lines_list: VBoxContainer = find_child('LinesList')
@onready var close: Button = %Close
@onready var empty: Label = %Empty
@onready var lines_scroll: ScrollContainer = %LinesScroll


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	# Connect to child signals
	close.pressed.connect(_destroy_history)
	
	# Connect to singletons signals
	G.history_opened.connect(_show_history)
	
	hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _show_history() -> void:
	if E.history.is_empty():
		empty.show()
		lines_scroll.hide()
	else:
		empty.hide()
		lines_scroll.show()
	
	for data in E.history:
		var lbl: Label
		
		if data.has('character'):
			lbl = DIALOG_LINE.instantiate()
			lbl.text = '%s: %s' % [data.character, data.text]
		else:
			lbl = INTERACTION_LINE.instantiate()
			lbl.text = '(%s)' % data.action
	
		_lines_list.add_child(lbl)
	
	if E.settings.scale_gui:
		scale = Vector2.ONE * E.scale
	
	G.blocked.emit({ blocking = false })
	
	Cursor.set_cursor(Cursor.Type.USE)
	Cursor.block()
	
	show()


func _destroy_history() -> void:
	for c in _lines_list.get_children():
		(c as Label).queue_free()
	
	G.done()
	Cursor.unlock()
	
	hide()
