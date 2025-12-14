# @popochiu-docs-ignore-class
@tool
extends PopochiuDialog


#region Virtual ####################################################################################
func _on_start() -> void:
	# Put setup logic here to run before showing dialog options.
	# Example: make the player face the character, say a line, or let the NPC reply:

#	await C.player.face_clicked()
#	await C.player.say("Hi")
#	await C.Popsy.say("Oh! Hi...")

	# NOTE: this method must await something to function correctly. By default, it awaits a frame.
	await PopochiuUtils.e.get_tree().process_frame


func _option_selected(opt: PopochiuDialogOption) -> void:
	# You can make the player say the selected option using:

#	await D.say_selected()

	# Use `match` to handle each option and run the corresponding logic.
	# For complex dialogs, create private functions to keep the code organized.
	match opt.id:
		_:
			# By default close the dialog. Options won't show after calling
			# stop()
			stop()

	_show_options()
	# Or remove this _option_selected function entirely and instead define
	# functions named after your options. 
	# For example with options "Option1", "DogJoke", "Surprise":
	#   func _on_option_option_1(opt): called when user picks "Option1"
	#   func _on_option_dog_joke(opt): called when user picks "DogJoke"
	#   func _on_option_surprise(opt): called when user picks "Surprise"


# Return a Dictionary of custom data to save for this PopochiuDialog.
# The Dictionary must contain only JSON-supported types: bool, int, float, String.
func _on_save() -> Dictionary:
	return {}


# Called when the game is loaded.
# The `data` Dictionary should match the structure returned by `_on_save()`.
func _on_load(data: Dictionary) -> void:
	prints(data)


#endregion
