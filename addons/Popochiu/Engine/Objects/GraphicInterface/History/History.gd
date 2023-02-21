extends Control
# warning-ignore-all:return_value_discarded

@onready var _lines_list: VBoxContainer = find_child('LinesList')
@onready var _dialog_line_path := scene_file_path.get_base_dir() + '/DialogLine.tscn'
@onready var _interaction_line_path := scene_file_path.get_base_dir() + '/InteractionLine.tscn'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	# Connect to child signals
	$Window.close_requested.connect(_destroy_history)
	
	# Connect to singletons signals
	G.history_opened.connect(_show_history)
	
	hide()
	$Window.hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _show_history() -> void:
	for data in E.history:
		var lbl: Label
		
		if data.has('character'):
			lbl = load(_dialog_line_path).instantiate()
			lbl.text = '%s: %s' % [data.character, data.text]
		else:
			lbl = load(_interaction_line_path).instantiate()
			lbl.text = '(%s)' % data.action
	
		_lines_list.add_child(lbl)
	
	if E.settings.scale_gui:
		scale = Vector2.ONE * E.scale
		$Window.scale = Vector2.ONE * E.scale
	
#	popup(Rect2(8, 16, 304, 160))
	$Window.popup_centered(Vector2(240.0, 120.0))
	
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
