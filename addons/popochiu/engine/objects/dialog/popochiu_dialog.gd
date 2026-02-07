@tool
@icon('res://addons/popochiu/icons/dialog.png')
class_name PopochiuDialog
extends Resource
## Represents a branching dialog tree with selectable options.
##
## Dialog options can trigger game events, be enabled or disabled at runtime, and track usage
## history. Override virtual methods to define dialog behavior.

## The identifier of the object used in scripts.
@export var script_name := ''
## The array of [PopochiuDialogOption] to show on screen when the dialog is running.
@export var options: Array[PopochiuDialogOption] = [] : set = set_options


#region Virtual ####################################################################################
## Called when the dialog starts.
## [b]You must use [code]await[/code] inside this method for the dialog to work properly.[/b]
##
## Implement this to add custom behavior (such as change the animation of a character) or update the
## game state when the dialog starts.
##
## [i]Virtual[/i].
func _on_start() -> void:
	pass


## Called when [param opt] (one of the dialog options) is clicked. Use
## [member PopochiuDialogOption.id] to identify which option was selected.[br]
## Implement this to add custom behavior (such as change the animation of a character, play a sound,
## etc.) or to update the game state when a dialog option is selected.
##
## [i]Virtual[/i].
func _option_selected(opt: PopochiuDialogOption) -> void:
	pass


## Called when the game is saved.[br]
## Implement this to persist custom properties that you added to this resource. Should return
## a [Dictionary] containing the data to be saved.[br]
## The returned [Dictionary] must contain only JSON-supported types:
## [bool], [int], [float], [String].
##
## [i]Virtual[/i].
func _on_save() -> Dictionary:
	return {}


## Called when the game is loaded. The structure of [param data] matches that returned by
## [method _on_save].[br]
## Implement this to restore the custom properties you persisted in [_on_save].
##
## [i]Virtual[/i].
func _on_load(_data: Dictionary) -> void:
	pass


#endregion

#region Public #####################################################################################
## Starts this dialog, then calls [method _on_start].
##
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_start() -> Callable:
	return func (): await start()


## Starts this dialog, then calls [method _on_start].
func start() -> void:
	if PopochiuUtils.d.current_dialog == self:
		return
	
	# Start this dialog
	PopochiuUtils.d.current_dialog = self
	await _start()


## Stops the dialog, hiding the options menu.
##
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_stop() -> Callable:
	return func (): await stop()


## Stops the dialog, hiding the options menu.
func stop() -> void:
	PopochiuUtils.d.finish_dialog()


## Enables each [PopochiuDialogOption] which [member PopochiuDialogOption.id] appears in the
## [param ids] array.
func turn_on_options(ids: Array) -> void:
	for id in ids:
		var opt: PopochiuDialogOption = get_option(id)
		if opt: opt.turn_on()


## Disables each [PopochiuDialogOption] which [member PopochiuDialogOption.id] appears in the
## [param ids] array.
func turn_off_options(ids: Array) -> void:
	for id in ids:
		var opt: PopochiuDialogOption = get_option(id)
		if opt: opt.turn_off()


## Disables [b]forever[/b] each [PopochiuDialogOption] which [member PopochiuDialogOption.id]
## appears in the [param ids] array.
func turn_off_forever_options(ids: Array) -> void:
	for id in ids:
		var opt: PopochiuDialogOption = get_option(id)
		if opt: opt.turn_off_forever()


# @popochiu-docs-ignore
#
## Called by the engine before saving the game.
func on_save() -> Dictionary:
	return _on_save()


# @popochiu-docs-ignore
#
## Called by the engine after loading a saved game.
func on_load(data: Dictionary) -> void:
	_on_load(data)


## Returns the dialog option whose [member PopochiuDialogOption.id] matches [param opt_id].
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
	PopochiuUtils.g.block()
	PopochiuUtils.d.dialog_started.emit(self)
	
	await _on_start()
	
	_show_options()
	
	await PopochiuUtils.d.dialog_finished
	
	PopochiuUtils.g.unblock()
	PopochiuUtils.d.option_selected.disconnect(_on_option_selected)


func _show_options() -> void:
	if not PopochiuUtils.d.active: return
	
	PopochiuUtils.d.dialog_options_requested.emit(options)
	
	if not PopochiuUtils.d.option_selected.is_connected(_on_option_selected):
		PopochiuUtils.d.option_selected.connect(_on_option_selected)


func _on_option_selected(opt: PopochiuDialogOption) -> void:
	opt.used = true
	opt.used_times += 1
	PopochiuUtils.d.selected_option = opt
	
	_option_selected(opt)


#endregion
