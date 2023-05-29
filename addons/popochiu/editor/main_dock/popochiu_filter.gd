@tool
extends LineEdit

var groups := {}: set = set_groups


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	right_icon = get_theme_icon('Search', 'EditorIcons')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func set_groups(value: Dictionary) -> void:
	groups = value
	
	if groups:
		text_changed.connect(
			_filter_rows.bind(groups),
			CONNECT_REFERENCE_COUNTED
		)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
# `source` is one of the `_types` dictionaries in PopochiuDock, TabRoom and
# TabAudio
func _filter_rows(new_text: String, source: Dictionary) -> void:
	for type_dic in source.values():
		type_dic.group.show()
		
		var title_in_filter := false
		
		if type_dic.group.title.findn(new_text) > -1:
			title_in_filter = true
		
		var hidden_rows := 0
		
		# type_dic.group is a PopochiuGroup
		var rows: Array = type_dic.group.get_elements()
		
		for row in rows:
			row.show()
			
			if new_text.is_empty(): continue
			
			if (row as Control).name.findn(new_text) < 0\
			and not title_in_filter:
				hidden_rows += 1
				row.hide()
		
		if hidden_rows == rows.size() and not new_text.is_empty():
			type_dic.group.hide()
