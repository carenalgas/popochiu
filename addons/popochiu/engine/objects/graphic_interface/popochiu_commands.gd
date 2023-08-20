class_name PopochiuCommands
extends RefCounted
## Defines the commands that can be used by players to interact with the objects
## in the game.


func _init() -> void:
	E.register_command(-1, "", fallback)


static func get_script_name() -> String:
	return "PopochiuCommands"


## Called by E when a command doesn't have a command method.
func fallback() -> void:
	print_rich("[rainbow]The default Popochiu command fallback[/rainbow]")
