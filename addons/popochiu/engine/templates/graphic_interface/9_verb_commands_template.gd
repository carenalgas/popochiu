extends NineVerbCommands


# Override this if you want to register additional commands. (!) Don't forget
# to call super().
#func _init() -> void:
	#super()


# Override this if you want to change the name that will identify this set of
# commands.
#static func get_script_name() -> String:
	#return "NineVerbCommands"


# Called when there is not a Callable defined for a registered command.
# By default calls `walk_to()`.
func fallback() -> void:
	super()


# Called when `E.current_command == Commands.WALK_TO` and E.command_fallback()
# is triggered.
func walk_to() -> void:
	super()


# Called when `E.current_command == Commands.OPEN` and E.command_fallback()
# is triggered.
func open() -> void:
	super()


# Called when `E.current_command == Commands.PICK_UP` and E.command_fallback()
# is triggered.
func pick_up() -> void:
	super()


# Called when `E.current_command == Commands.PUSH` and E.command_fallback()
# is triggered.
func push() -> void:
	super()


# Called when `E.current_command == Commands.CLOSE` and E.command_fallback()
# is triggered.
func close() -> void:
	super()


# Called when `E.current_command == Commands.LOOK_AT` and E.command_fallback()
# is triggered.
func look_at() -> void:
	super()


# Called when `E.current_command == Commands.PULL` and E.command_fallback()
# is triggered.
func pull() -> void:
	super()


# Called when `E.current_command == Commands.GIVE` and E.command_fallback()
# is triggered.
func give() -> void:
	super()


# Called when `E.current_command == Commands.TALK_TO` and E.command_fallback()
# is triggered.
func talk_to() -> void:
	super()


# Called when `E.current_command == Commands.USE` and E.command_fallback()
# is triggered.
func use() -> void:
	super()
