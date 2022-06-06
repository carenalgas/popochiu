extends Node
# (D) Data and functions to start branching dialogs and listen options selection.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

signal option_selected(opt)
signal dialog_options_requested(options)
signal dialog_finished
signal inline_dialog_requested(options)

const PopochiuDialogOption :=\
preload('res://addons/Popochiu/Engine/Objects/Dialog/PopochiuDialogOption.gd')

var active := false

var _trees := []


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Starts a branching dialog identified by its script_name
func show_dialog(script_name: String) -> void:
	var dialog: PopochiuDialog = E.get_dialog(script_name)
	
	if dialog:
		active = true
		dialog.start()
		
		yield(D, 'dialog_finished')
		
		active = false
		G.done()
	else:
		yield(get_tree(), 'idle_frame')


# Shows a list of options (like a dialog tree would do) and returns the
# PopochiuDialogOption of the selected option
func show_inline_dialog(opts: Array) -> PopochiuDialogOption:
	emit_signal('inline_dialog_requested', opts)
	return yield(D, 'option_selected')


# Finishes the dialog currently in execution.
func finish_dialog() -> void:
	emit_signal('dialog_finished')
