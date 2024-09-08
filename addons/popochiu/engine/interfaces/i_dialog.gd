class_name PopochiuIDialog
extends Node
## Provides access to the [PopochiuDialog]s in the game. Access with [b]D[/b] (e.g.
## [code]D.AskAboutLoom.start()[/code]).
##
## Use it to work with branching dialogs and listen to options selection. Its script is
## [b]i_dialog.gd[/b].[br][br]
##
## Some things you can do with it:[br][br]
## [b]•[/b] Start a branching dialog.[br]
## [b]•[/b] Know when a dialog has finished, or an option in the current list of options is
## selected.[br]
## [b]•[/b] Create a list of options on the fly.[br][br]
##
## Example:
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

## Emitted when [param dlg] starts.
signal dialog_started(dlg: PopochiuDialog)
## Emitted when an [param opt] is selected in the current dialog.
signal option_selected(opt: PopochiuDialogOption)
## Emitted when [param dlg] finishes.
signal dialog_finished(dlg: PopochiuDialog)
## Emitted when the list of available [param options] in the current dialog is requested.
signal dialog_options_requested(options: Array[PopochiuDialogOption])
## Emitted when an inline dialog is created based on a list of [param options].
signal inline_dialog_requested(options: Array)

## Whether a dialog is playing.
var active := false
## Stores data about the state of each [PopochiuDialog] in the game. The key of each entry is the
## [member PopochiuDialog.script_name] of the dialog.
var trees := {}
## Provides access to the dialog that is currently playing.
var current_dialog: PopochiuDialog = null : set = set_current_dialog
## Provides access to the currently selected option in the dialog that is currently playing.
var selected_option: PopochiuDialogOption = null
## Provides access to the branching dialog that was played before the current one. I.e. Could be
## used to return to the previous dialog after exhausting the options in the currently playing one.
var prev_dialog: PopochiuDialog = null


#region Public #####################################################################################
## Displays a list of [param options], similar to a branching dialog, and returns the selected
## [PopochiuDialogOption].
func show_inline_dialog(options: Array) -> PopochiuDialogOption:
	active = true
	
	if current_dialog:
		D.option_selected.disconnect(current_dialog._on_option_selected)
	
	inline_dialog_requested.emit(options)
	
	var pdo: PopochiuDialogOption = await option_selected
	
	if current_dialog:
		D.option_selected.connect(current_dialog._on_option_selected)
	else:
		active = false
		G.unblock()
	
	return pdo


## Halts the currently playing [PopochiuDialog].
func finish_dialog() -> void:
	dialog_finished.emit(current_dialog)


## Makes the Player-controlled Character (PC) to say the selected option in a branching dialog.
func say_selected() -> void:
	await C.player.say(selected_option.text)

## Transforms any text to gibberish preserving bbcode tags
func create_gibberish(input_string: String) -> String:
	var output_text: String = ""
	var bbcode: bool = false
	var letters = ['a','e','i','o','u','y','b','c','d','f','g','h','j','k','l','m','n','p','q','r','s','t','v','w','x','z']
	for chr in input_string:
		if(chr == '['):
			bbcode = true
		elif(chr == ']'):
			output_text += chr
			bbcode = false
			continue
		
		if (!bbcode):
			if (chr != ' '):
					output_text += letters[randi_range(0,letters.size()-1)]
			else:
				output_text += ' ' 
		else:
			output_text += chr
			
	return output_text

## @deprecated
## Now it is [method get_instance].
func get_dialog_instance(script_name: String) -> PopochiuDialog:
	return get_instance(script_name)


## Gets the instance of the [PopochiuDialog] identified with [param script_name].
func get_instance(script_name: String) -> PopochiuDialog:
	var tres_path: String = PopochiuResources.get_data_value("dialogs", script_name, "")

	if not tres_path:
		PopochiuUtils.print_error("Dialog [b]%s[/b] doesn't exist in the project" % script_name)
		return null

	return load(tres_path)


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
