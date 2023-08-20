class_name SierraCommands
extends PopochiuCommands

enum Commands {
	WALK, LOOK, INTERACT, TALK
}


func _init() -> void:
	super()
	
	E.register_command(Commands.WALK, "Walk", walk)
	E.register_command(Commands.LOOK, "Look", look)
	E.register_command(Commands.INTERACT, "Interact", interact)
	E.register_command(Commands.TALK, "Talk", talk)


static func get_script_name() -> String:
	return "SierraCommands"


## Called when there is not a Callable defined for a registered command.
func fallback() -> void:
	walk()


## Called when `E.current_command == Commands.WALK` and E.command_fallback()
## is triggered.
## By default makes the character walk to the clicked `PopochiuClickable`.
func walk() -> void:
#	E.get_node("/root/C").walk_to_clicked()
	C.walk_to_clicked()


## Called when `E.current_command == Commands.LOOK` and E.command_fallback()
## is triggered.
func look() -> void:
	G.show_system_text(
		"%s has nothing to say about that object" % C.player.description
	)


## Called when `E.current_command == Commands.INTERACT` and E.command_fallback()
## is triggered.
func interact() -> void:
	G.show_system_text(
		"%s doesn't want to do anything with that object" % C.player.description
	)


## Called when `E.current_command == Commands.TALK` and E.command_fallback()
## is triggered.
func talk() -> void:
	G.show_system_text(
		"%s can't talk with that" % C.player.description
	)
