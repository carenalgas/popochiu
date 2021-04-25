extends Node

signal option_selected(opt)
signal dialog_requested
signal dialog_finished

export(Array, Resource) var trees := []

var active := false


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func show_dialog(script_name: String) -> void:
	for t in trees:
		var tree: DialogTree = t
		if tree.script_name.to_lower() == script_name.to_lower():
			active = true
			tree.start()
			yield(D, 'dialog_finished')
			active = false
			G.done()
	# Por si no se encuentra el diálogo
	yield(get_tree(), 'idle_frame')
