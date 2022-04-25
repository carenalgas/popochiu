extends Node
# (D) To start branching dialogs and listen options selection.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

signal option_selected(opt)
signal dialog_requested
signal dialog_finished

var active := false

var _trees := []


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
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
