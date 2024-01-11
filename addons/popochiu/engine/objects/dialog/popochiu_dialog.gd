@tool
@icon('res://addons/popochiu/icons/dialog.png')
class_name PopochiuDialog extends Resource
## A class for branching dialogs. Can have dialog options that trigger a script when selected.

const PopochiuDialogOption := preload('popochiu_dialog_option.gd')

@export var options := [] : set = set_options
@export var script_name := ''


#region Virtual ####################################################################################
func _on_start() -> void:
	pass


func _option_selected(opt: PopochiuDialogOption) -> void:
	pass


func _on_save() -> Dictionary:
	return {}


func _on_load(_data: Dictionary) -> void:
	pass


#endregion

#region Public #####################################################################################
func start() -> void:
	# Start this dialog
	D.current_dialog = self
	await _start()


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


## Use this to save custom data for this PopochiuDialog when saving the game.
## The Dictionary must contain only JSON supported types: bool, int, float, String.
func on_save() -> Dictionary:
	return _on_save()


## Called when the game is loaded.
## This Dictionary should has the same structure you defined for the returned one in _on_save().
func on_load(data: Dictionary) -> void:
	_on_load(data)


#endregion

#region SetGet #####################################################################################
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


#endregion

#region Private ####################################################################################
func _start() -> void:
	G.block()
	D.dialog_started.emit(self)
	
	await _on_start()
	
	_show_options()
	
	await D.dialog_finished
	
	G.unblock()
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


#endregion
