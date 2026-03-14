# @popochiu-docs-ignore-class
extends NineVerbCommands


# Override this to register additional commands.
# Note: any override must call `super()` to preserve base registration.
#func _init() -> void:
	#super()


# Override this to change the identifying name for this command set.
#static func get_script_name() -> String:
	#return "NineVerbCommands"


# Called when a registered command has no Callable defined.
# By default this calls `walk_to()`. Override to implement a different fallback behavior.
func fallback() -> void:
	super()


# Called when `E.current_command == Commands.WALK_TO` and `E.command_fallback()` is triggered.
func walk_to() -> void:
	super()


# Called when `E.current_command == Commands.OPEN` and `E.command_fallback()` is triggered.
func open() -> void:
	super()


# Called when `E.current_command == Commands.PICK_UP` and `E.command_fallback()` is triggered.
func pick_up() -> void:
	super()


# Called when `E.current_command == Commands.PUSH` and `E.command_fallback()` is triggered.
func push() -> void:
	super()


# Called when `E.current_command == Commands.CLOSE` and `E.command_fallback()` is triggered.
func close() -> void:
	super()


# Called when `E.current_command == Commands.LOOK_AT` and `E.command_fallback()` is triggered.
func look_at() -> void:
	super()


# Called when `E.current_command == Commands.PULL` and `E.command_fallback()` is triggered.
func pull() -> void:
	super()


# Called when `E.current_command == Commands.GIVE` and `E.command_fallback()` is triggered.
func give() -> void:
	super()


# Called when `E.current_command == Commands.TALK_TO` and `E.command_fallback()` is triggered.
func talk_to() -> void:
	super()


# Called when `E.current_command == Commands.USE` and `E.command_fallback()` is triggered.
func use() -> void:
	super()
