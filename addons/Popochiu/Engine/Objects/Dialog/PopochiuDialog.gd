tool
class_name PopochiuDialog, 'res://addons/Popochiu/icons/dialog.png'
extends Resource
# For branching dialog, can have dialog options that trigger a script.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

const PopochiuDialogOption := preload('PopochiuDialogOption.gd')

export(Array, Resource) var options := [] setget set_options
export var script_name := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func on_start() -> void:
	pass


func option_selected(opt: PopochiuDialogOption) -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func start() -> void:
	yield(on_start(), 'completed')
	
	_show_options()
	
	yield(D, 'dialog_finished')
	
	D.disconnect('option_selected', self, '_on_option_selected')


func stop() -> void:
	D.finish_dialog()


# Gets the option PopochiuDialogOption.id that matches opt_id
func get_option(opt_id: String) -> PopochiuDialogOption:
	for o in options:
		if (o as PopochiuDialogOption).id == opt_id:
			return o
	return null


func turn_on_options(ids: Array) -> void:
	for id in ids:
		var opt: PopochiuDialogOption = get_option(id)
		if opt: opt.turn_on()


func turn_off_options(ids: Array) -> void:
	for id in ids:
		var opt: PopochiuDialogOption = get_option(id)
		if opt: opt.turn_off()


func turn_off_forever_options(ids: Array) -> void:
	for id in ids:
		var opt: PopochiuDialogOption = get_option(id)
		if opt: opt.turn_off_forever()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func set_options(value: Array) -> void:
	options = value
	
	for v in value.size():
		if not value[v]:
			var new_opt: PopochiuDialogOption = PopochiuDialogOption.new()
			var id := 'Opt%d' % options.size()
			
			new_opt.id = id
			new_opt.text = 'Option %d' % options.size()
			options[v] = new_opt
			
			property_list_changed_notify()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _show_options() -> void:
	if not D.active: return
	
	D.emit_signal('dialog_options_requested', options)
	
	if not D.is_connected('option_selected', self, '_on_option_selected'):
		D.connect('option_selected', self, '_on_option_selected')


func _on_option_selected(opt: PopochiuDialogOption) -> void:
	opt.used = true
	opt.used_times += 1
	D.selected_option = opt
	
	option_selected(opt)
