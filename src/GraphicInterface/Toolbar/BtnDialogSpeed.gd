extends ToolbarButton

export var speeds_description := ['normal', 'rápido', 'inmediato']

func _get_description() -> String:
	return '%s: %s' % [description, speeds_description[E.text_speed_idx]]
