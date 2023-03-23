# For branching dialog, can have dialog options that trigger a script.
@tool
@icon('res://addons/popochiu/icons/dialog.png')
class_name PopochiuDialog
extends Resource

const PopochiuDialogOption := preload('popochiu_dialog_option.gd')

@export var options := [] : set = set_options
@export var script_name := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _on_start() -> void:
	pass


func _option_selected(opt: PopochiuDialogOption) -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func start() -> void:
	# Start this dialog
	D.current_dialog = self
	
	await _start()
	
	G.done()


func queue_start() -> Callable:
	return func (): await start()


func stop() -> void:
	D.finish_dialog()


func queue_stop() -> Callable:
	return func (): await stop()


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
			
			notify_property_list_changed()


# Gets the option PopochiuDialogOption.id that matches opt_id
func get_option(opt_id: String) -> PopochiuDialogOption:
	for o in options:
		if (o as PopochiuDialogOption).id == opt_id:
			return o
	return null


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _start() -> void:
	await _on_start()
	
	_show_options()
	
	await D.dialog_finished
	
	D.option_selected.disconnect(_on_option_selected)


func _show_options() -> void:
	if not D.active: return
	
	D.dialog_options_requested.emit(options)
	
	if not D.option_selected.is_connected(_on_option_selected):
		D.option_selected.connect(_on_option_selected)


func _on_option_selected(opt: PopochiuDialogOption) -> void:
	opt.used = true
	opt.used_times += 1
	D.selected_option = opt
	
	_option_selected(opt)
