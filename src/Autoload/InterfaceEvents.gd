extends Node

signal show_info_requested(info)
signal show_box_requested(message)
signal inline_dialog_requested(options)
signal continue_clicked
signal freed

# TODO: Estas señales tendrán que ir en el Autoload destinado al sistema de
# diálogo.
signal option_selected(opt)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func display(msg: String) -> void:
	emit_signal('show_box_requested', msg)
	yield(self, 'continue_clicked')


func done() -> void:
	emit_signal('freed')


func show_info(msg: String) -> void:
	emit_signal('show_info_requested', msg)


func show_inline_dialog(opts: Array) -> String:
	emit_signal('inline_dialog_requested', opts)
	return yield(self, 'option_selected')
