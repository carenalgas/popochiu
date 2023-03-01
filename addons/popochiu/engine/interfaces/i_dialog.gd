# (D) Data and functions to start branching dialogs and listen options selection.
extends Node

signal option_selected(opt)
signal dialog_options_requested(options)
signal dialog_finished
signal inline_dialog_requested(options)

const PopochiuDialogOption :=\
preload('res://addons/popochiu/engine/objects/dialog/popochiu_dialog_option.gd')

var active := false
var trees := {}
var current_dialog: PopochiuDialog = null
var selected_option: PopochiuDialogOption = null
var prev_dialog: PopochiuDialog = null


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Starts a branching dialog identified by its script_name
func show_dialog(script_name: String) -> void:
	current_dialog = E.get_dialog(script_name)
	
	if current_dialog:
		active = true
		current_dialog._start()
		
		await self.dialog_finished
		
		# Save the state of the dialog
		trees[current_dialog.script_name] = current_dialog
		
		active = false
		current_dialog = null
		selected_option = null
		
		G.done()
	else:
		await get_tree().process_frame


# Shows a list of options (like a dialog tree would do) and returns the
# PopochiuDialogOption of the selected option
func show_inline_dialog(opts: Array) -> PopochiuDialogOption:
	active = true
	
	if current_dialog:
		D.option_selected.disconnect(current_dialog._on_option_selected)
	
	inline_dialog_requested.emit(opts)
	
	var pdo: PopochiuDialogOption = await option_selected
	
	if current_dialog:
		D.option_selected.connect(current_dialog._on_option_selected)
	else:
		active = false
		G.done()
	
	return pdo


# Finishes the dialog currently in execution.
func finish_dialog() -> void:
	dialog_finished.emit()


func say_selected() -> void:
	await E.run(['Player: ' + selected_option.text])
