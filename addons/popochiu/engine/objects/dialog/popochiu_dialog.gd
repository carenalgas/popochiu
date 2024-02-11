@tool
@icon('res://addons/popochiu/icons/dialog.png')
class_name PopochiuDialog
extends Resource
## A class for branching dialogs. The dialog options can be used to trigger events.

## The identifier of the object used in scripts.
@export var script_name := ''
## The array of [PopochiuDialogOption] to show on screen when the dialog is running.
@export var options: Array[PopochiuDialogOption] = [] : set = set_options


#region Virtual ####################################################################################
## Called when the dialog starts. [b]You have to use an [code]await[/code] in this method in order
## to make the dialog to work properly[/b].
## [i]Virtual[/i].
func _on_start() -> void:
	pass


## Called when the [param opt] dialog option is clicked. The [member PopochiuDialogOption.id] in
## [param opt] can be used to check which was the selected option.
## [i]Virtual[/i].
func _option_selected(opt: PopochiuDialogOption) -> void:
	pass


## Called when the game is saved.
## [i]Virtual[/i].
func _on_save() -> Dictionary:
	return {}


## Called when the game is loaded. The structure of [param data] is the same returned by
## [method _on_save].
## [i]Virtual[/i].
func _on_load(_data: Dictionary) -> void:
	pass


#endregion

#region Public #####################################################################################
## Starts this dialog, then [method _on_start] is called.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_start() -> Callable:
	return func (): await start()


## Starts this dialog, then [method _on_start] is called.
func start() -> void:
	# Start this dialog
	D.current_dialog = self
	await _start()


## Stops the dialog (which makes the menu with the options to disappear).
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_stop() -> Callable:
	return func (): await stop()


## Stops the dialog (which makes the menu with the options to disappear).
func stop() -> void:
	D.finish_dialog()


## Enables each [PopochiuDialogOption] which [member PopochiuDialogOption.id] matches each of the
## values in the [param ids] array.
func turn_on_options(ids: Array) -> void:
	for id in ids:
		var opt: PopochiuDialogOption = get_option(id)
		if opt: opt.turn_on()


## Disables each [PopochiuDialogOption] which [member PopochiuDialogOption.id] matches each of the
## values in the [param ids] array.
func turn_off_options(ids: Array) -> void:
	for id in ids:
		var opt: PopochiuDialogOption = get_option(id)
		if opt: opt.turn_off()


## Disables [b]forever[/b] each [PopochiuDialogOption] which [member PopochiuDialogOption.id]
## matches each of the values in the [param ids] array.
func turn_off_forever_options(ids: Array) -> void:
	for id in ids:
		var opt: PopochiuDialogOption = get_option(id)
		if opt: opt.turn_off_forever()


## Use this to save custom data when saving the game. The returned [Dictionary] must contain only
## JSON supported types: [bool], [int], [float], [String].
func on_save() -> Dictionary:
	return _on_save()


## Called when the game is loaded. [param data] will have the same structure you defined for the
## returned [Dictionary] by [method _on_save].
func on_load(data: Dictionary) -> void:
	_on_load(data)


## Returns the dilog option which [member PopochiuDialogOption.id] matches [param opt_id].
func get_option(opt_id: String) -> PopochiuDialogOption:
	for o in options:
		if (o as PopochiuDialogOption).id == opt_id:
			return o
	return null


#endregion

#region SetGet #####################################################################################
func set_options(value: Array[PopochiuDialogOption]) -> void:
	options = value
	
	for idx in value.size():
		if not value[idx]:
			var new_opt: PopochiuDialogOption = PopochiuDialogOption.new()
			var id := 'Opt%d' % options.size()
			
			new_opt.id = id
			new_opt.text = 'Option %d' % options.size()
			options[idx] = new_opt


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
