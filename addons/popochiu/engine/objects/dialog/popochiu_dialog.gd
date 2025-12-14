# @popochiu-docs-category game-objects
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

var _has_done_init := false


#region Virtual ####################################################################################
## Called when the dialog is first accessed (before it starts).
## [b]Return an array of PopochiuDialogOptions created with [method create_option][/b].
##
## To mix creating options from code and inspector, add your options to [param existing_options]:
## [codeblock]
## existing_options.append_array([
##     create_option("Joke1", {
##       text = "What do you call a magic dog?",
##     }),
## ])
## return existing_options
## [/codeblock]
##
## Overriding this function is optional. You can configure your dialog using the Inspector.
## [i]Virtual[/i].
func _on_build_options(existing_options: Array[PopochiuDialogOption]) -> Array[PopochiuDialogOption]:
	return existing_options


## Called when the dialog starts.
## [b]You must use [code]await[/code] inside this method for the dialog to work properly.[/b]
##
## Implement this to add custom behavior (such as change the animation of a character) or update the
## game state when the dialog starts.
func _on_start() -> void:
	pass


## Called when [param opt] (one of the dialog options) is clicked. Use
## [member PopochiuDialogOption.id] to identify which option was selected.[br]
## Implement this to add custom behavior (such as change the animation of a character, play a sound,
## etc.) or to update the game state when a dialog option is selected.
##
## Instead of overriding this function, you can write functions for each option using their
## [snake_case](https://docs.godotengine.org/en/stable/classes/class_string.html#class-string-method-to-snake-case)
## name (option id BYE2 will call [code]_on_option_bye_2[/code]).
## [i]Virtual[/i].
func _option_selected(opt: PopochiuDialogOption) -> void:
	pass


## Called when the game is saved.[br]
## Implement this to persist custom properties that you added to this resource. Should return
## a [Dictionary] containing the data to be saved.[br]
## The returned [Dictionary] must contain only JSON-supported types:
## [bool], [int], [float], [String].
func _on_save() -> Dictionary:
	return {}


## Called when the game is loaded. The structure of [param data] matches that returned by
## [method _on_save].[br]
## Implement this to restore the custom properties you persisted in [_on_save].
func _on_load(_data: Dictionary) -> void:
	pass


#endregion

#region Public #####################################################################################
## Call this from within [method _on_build_options] to populate your dialog options (instead
## of using the Inspector).
##
## Optionally use [param config] to create the list of options in one block:
## [codeblock]
## return [
##     create_option("OfferHelp", {
##             text = "What can I do for you?",
##         }),
##     create_option("Bye", {
##             text = "Going get you some food, hold on.",
##             visible = false,
##         }),
## ]
## [/codeblock]
func create_option(id: String, config: Dictionary = {}) -> PopochiuDialogOption:
	var opt = PopochiuDialogOption.new()
	opt.set_id(id)
	if not config.is_empty():
		opt.configure(config)
		if opt.text.is_empty():
			# User made a typo or forgot essential element in their construction dictionary.
			PopochiuUtils.print_error("%s's PopochiuDialogOption '%s' needs text for it to appear in a conversation: create_option('%s', { text = 'Hello.' })" % [self.script_name, id, id])
	return opt


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

## Called by PopochiuIDialog before returning the list of options for a dialogue.
## NOTE: This funciton is for internal engine use only and is not supposed to
## be used in game scripts.
func build_options():
	if _has_done_init:
		return
	_has_done_init = true

	# Use assign() to avoid type errors if user doesn't have type hints or uses
	# options + [] in _on_build_options.
	var typed_opts: Array[PopochiuDialogOption] = []
	typed_opts.assign(_on_build_options(options))
	options = typed_opts


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

	# Convert option so function names match Godot coding guidelines.
	var fn = "_on_option_" + opt.id.to_snake_case()
	if has_method(fn):
		await call(fn, opt)
		_show_options()


#endregion
