extends ToolbarButton


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_pressed() -> void:
	for h in E.dialog_history:
		prints('%s: %s' % [h.character, h.text])
