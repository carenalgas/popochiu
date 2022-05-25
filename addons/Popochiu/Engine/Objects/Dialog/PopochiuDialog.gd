tool
class_name PopochiuDialog, 'res://addons/Popochiu/icons/dialog.png'
extends Resource
# For branching dialog, can have dialog options that trigger a script.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

const PopochiuDialogOption := preload('PopochiuDialogOption.gd')

export(Array, Resource) var options := [] setget _set_options
export var script_name := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func start() -> void:
	_show_options()
	yield(D, 'dialog_finished')
	D.disconnect('option_selected', self, 'option_selected')


func option_selected(opt: PopochiuDialogOption) -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _show_options() -> void:
	D.emit_signal('dialog_options_requested', options)
	if not D.is_connected('option_selected', self, 'option_selected'):
		D.connect('option_selected', self, 'option_selected')


func _set_options(value: Array) -> void:
	options = value
	for v in value.size():
		if not value[v]:
			var new_opt: PopochiuDialogOption = PopochiuDialogOption.new()
			var id := 'Opt%d' % options.size()
			new_opt.id = id
			new_opt.text = 'Option %d' % options.size()
			options[v] = new_opt
			property_list_changed_notify()
