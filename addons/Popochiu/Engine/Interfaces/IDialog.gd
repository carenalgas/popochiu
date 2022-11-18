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
var trees := {}
var current_dialog: PopochiuDialog = null
var selected_option: PopochiuDialogOption = null


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Starts a branching dialog identified by its script_name
func show_dialog(script_name: String) -> void:
	current_dialog = E.get_dialog(script_name)
	
	if current_dialog:
		active = true
		current_dialog.start()
		
		yield(self, 'dialog_finished')
		
		trees[current_dialog.script_name] = current_dialog
		
		active = false
		current_dialog = null
		selected_option = null
		
		G.done()
	else:
		yield(get_tree(), 'idle_frame')


# Shows a list of options (like a dialog tree would do) and returns the
# PopochiuDialogOption of the selected option
func show_inline_dialog(opts: Array) -> PopochiuDialogOption:
	emit_signal('inline_dialog_requested', opts)
	return yield(self, 'option_selected')


# Finishes the dialog currently in execution.
func finish_dialog() -> void:
	emit_signal('dialog_finished')


func say_selected() -> void:
	yield(E.run(['Player: ' + selected_option.text]), 'completed')
