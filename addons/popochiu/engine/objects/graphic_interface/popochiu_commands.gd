class_name PopochiuCommands
extends RefCounted
## Defines the commands that can be used by players to interact with the objects in the game.


#region Godot ######################################################################################
func _init() -> void:
	E.register_command(-1, "", fallback)


#endregion

#region Public #####################################################################################
## Should return the name of this class, or the identifier you want to use in scripts to know the
## type of the current GUI commands.
static func get_script_name() -> String:
	return "PopochiuCommands"


## Called by [Popochiu] when a command doesn't have an associated [Callable].
func fallback() -> void:
	PopochiuUtils.print_normal("[rainbow]The default Popochiu command fallback[/rainbow]")


#endregion
