# @popochiu-docs-category game-scripts-interfaces
class_name PopochiuIDialog
extends Node
## Provides access to the project's [PopochiuDialog]s via the singleton [b]D[/b] (for example:
## [code]D.AskAboutLoom.start()[/code]).
##
## Use this interface to start and manage branching dialogs and to listen for option selection
## events.
##
## Capabilities include:
##
## - Start a branching dialog.[br]
## - Detect when a dialog finishes or when an option is selected.[br]
## - Create and show an inline list of options at runtime.
##
## [b]Use examples:[/b]
## [codeblock]
## func on_click() -> void:
##    # Create a dialog with 3 options
##    var opt: PopochiuDialogOption = await D.show_inline_dialog([
##        "Ask Popsy something", "Give Popsy a hug", "Do nothing"
##    ])
##
##    # The options IDs will go from 0 to the size - 1 of the array passed to D.show_inline_dialog
##    match opt.id:
##        "0": # "Ask Popsy something" was selected
##            D.ChatWithPopsy.start() # Start the ChatWithPopsy dialog
##        "1": # "Give Popsy a hug"  was selected
##            await C.walk_to_clicked()
##            await C.player.play_hug()
##        "2": # "Do nothing" was selected
##            await C.player.say("Maybe later...")
## [/codeblock]


## Emitted when [param dlg] starts playing.
signal dialog_started(dlg: PopochiuDialog)
## Emitted when an [param opt] is selected in the current dialog.
signal option_selected(opt: PopochiuDialogOption)
## Emitted when [param dlg] finishes.
signal dialog_finished(dlg: PopochiuDialog)
## Emitted when the list of available [param options] for the current dialog is requested.
signal dialog_options_requested(options: Array[PopochiuDialogOption])
## Emitted when an inline dialog is created. It carries the list of configured [param options].
signal inline_dialog_requested(options: Array)

## Whether a dialog is currently active.
var active := false
## Stores the runtime state of every [PopochiuDialog] in the project.
## Keys are each dialog's [member PopochiuDialog.script_name].
var trees := {}
## Currently running dialog instance. Setter handles lifecycle (waits for the current dialog
## to finish) and state saving.[br]
## Can be [code]null[/code] if no dialog is active.
var current_dialog: PopochiuDialog = null : set = set_current_dialog
## Currently selected option in the active dialog.
var selected_option: PopochiuDialogOption = null
## The previous branch that has been ran in the dialog tree;
## useful to return after exhausting options.
var prev_dialog: PopochiuDialog = null


#region Godot ######################################################################################
func _init() -> void:
	Engine.register_singleton(&"D", self)


#endregion

#region Public #####################################################################################
## Displays an inline list of [PopochiuDialogOption] [param options] and returns the selected one.
## While the inline dialog is shown, the dialog system is marked active. Restores previous dialog
## option handling once selection completes.
func show_inline_dialog(options: Array) -> PopochiuDialogOption:
	active = true
	
	if current_dialog:
		PopochiuUtils.d.option_selected.disconnect(current_dialog._on_option_selected)
	
	inline_dialog_requested.emit(options)
	
	var pdo: PopochiuDialogOption = await option_selected
	
	if current_dialog:
		PopochiuUtils.d.option_selected.connect(current_dialog._on_option_selected)
	else:
		active = false
		PopochiuUtils.g.unblock()
	
	return pdo


## Stops the currently running [PopochiuDialog] by emitting [signal dialog_finished].
func finish_dialog() -> void:
	dialog_finished.emit(current_dialog)


## Makes the Player-controlled Character (PC) speak the text of [member selected_option].
func say_selected() -> void:
	await PopochiuUtils.c.player.say(selected_option.text)


## Converts [param input_string] to gibberish while preserving bbcode tags. Returns the transformed [String].
##
## Main use case:[br]
##  - mask possible spoilers in pre-release or demo builds
##
## Other uses:[br]
##  - make clear that a character is speaking a language unknown to the player until a translation item is found[br]
##  - create humorous effect when the player is confused, drunk or otherwise not fully aware[br]
func create_gibberish(input_string: String) -> String:
	var output_text := ""
	var bbcode := false
	var letters := [
		"a","e","i","o","u",
		"y","b","c","d","f","g","h","j","k","l","m","n","p","q","r","s","t","v","w","x","z"
	]
	for chr in input_string:
		if(chr == "["):
			bbcode = true
		elif(chr == "]"):
			output_text += chr
			bbcode = false
			continue
		
		if (!bbcode):
			if (chr != " "):
					output_text += letters[randi_range(0,letters.size()-1)]
			else:
				output_text += " " 
		else:
			output_text += chr
	return output_text


## Loads and returns the [PopochiuDialog] resource identified by [param script_name] as defined in
## Instantiates and returns the [PopochiuDialog] resource referenced by [param script_name] from
## project data. Logs an error and returns [code]null[/code] if not found.
func get_instance(script_name: String) -> PopochiuDialog:
	var tres_path: String = PopochiuResources.get_data_value("dialogs", script_name, "")

	if not tres_path:
		PopochiuUtils.print_error("Dialog [b]%s[/b] doesn't exist in the project" % script_name)
		return null

	var d := load(tres_path)
	d.build_options()
	return d


#endregion

#region SetGet #####################################################################################
func set_current_dialog(value: PopochiuDialog) -> void:
	current_dialog = value
	active = true
	
	await self.dialog_finished
	
	# Save the state of the dialog
	trees[current_dialog.script_name] = current_dialog
	
	active = false
	current_dialog = null
	selected_option = null


#endregion
