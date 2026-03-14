# @popochiu-docs-ignore-class
extends SierraCommands


func _init() -> void:
	super()


static func get_script_name() -> String:
	return "SierraCommands"


# Called when a registered command has no Callable defined.
# By default this calls `walk()`. Override to implement a different fallback behavior.
func fallback() -> void:
	super()


# Called when `E.current_command == Commands.WALK` and `E.command_fallback()` is triggered.
# By default makes the character walk to the clicked `PopochiuClickable`.
func walk() -> void:
	super()


# Called when `E.current_command == Commands.LOOK` and `E.command_fallback()` is triggered.
func look() -> void:
	super()


# Called when `E.current_command == Commands.INTERACT` and `E.command_fallback()` is triggered.
func interact() -> void:
	super()


# Called when `E.current_command == Commands.TALK` and `E.command_fallback()` is triggered.
func talk() -> void:
	super()
