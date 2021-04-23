extends Node

signal show_info_requested(info)
signal show_box_requested(message)
signal show_inline_dialog(options)
signal continue_clicked
signal freed


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func display(msg: String) -> void:
	emit_signal('show_box_requested', msg)
	yield(self, 'continue_clicked')


func done() -> void:
	emit_signal('freed')


func show_info(msg: String) -> void:
	emit_signal('show_info_requested', msg)
