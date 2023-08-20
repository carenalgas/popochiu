class_name NineVerbCommands
extends PopochiuCommands

enum Commands {
	WALK_TO, OPEN, PICK_UP, PUSH, CLOSE, LOOK_AT, PULL, GIVE, TALK_TO, USE
}


func _init() -> void:
	super()
	
	E.register_command(Commands.WALK_TO, "Walk to", walk_to)
	E.register_command(Commands.OPEN, "Open", open)
	E.register_command(Commands.PICK_UP, "Pick up", pick_up)
	E.register_command(Commands.PUSH, "Push", push)
	E.register_command(Commands.CLOSE, "Close", close)
	E.register_command(Commands.LOOK_AT, "Look at", look_at)
	E.register_command(Commands.PULL, "Pull", pull)
	E.register_command(Commands.GIVE, "Give", give)
	E.register_command(Commands.TALK_TO, "Talk to", talk_to)
	E.register_command(Commands.USE, "Use", use)


static func get_script_name() -> String:
	return "NineVerbCommands"


## Called when there is not a Callable defined for a registered command.
func fallback() -> void:
	walk_to()


## Called when `E.current_command == Commands.WALK_TO` and E.command_fallback()
## is triggered.
## By default makes the character walk to the clicked `PopochiuClickable`.
func walk_to() -> void:
#	E.get_node("/root/C").walk_to_clicked()
	C.player.walk_to_clicked()
	
	await C.player.move_ended
	
	if E.clicked and E.clicked.get("suggested_command")\
	and E.clicked.last_click_button == MOUSE_BUTTON_RIGHT:
		E.current_command = E.clicked.suggested_command
		E.clicked.handle_command(MOUSE_BUTTON_LEFT)


## Called when `E.current_command == Commands.OPEN` and E.command_fallback()
## is triggered.
func open() -> void:
	C.player.say("Can't open that")


## Called when `E.current_command == Commands.PICK_UP` and E.command_fallback()
## is triggered.
func pick_up() -> void:
	C.player.say("Not picking that up")


## Called when `E.current_command == Commands.PUSH` and E.command_fallback()
## is triggered.
func push() -> void:
	C.player.say("I don't want to push that")


## Called when `E.current_command == Commands.CLOSE` and E.command_fallback()
## is triggered.
func close() -> void:
	C.player.say("Can't close that")


## Called when `E.current_command == Commands.LOOK_AT` and E.command_fallback()
## is triggered.
func look_at() -> void:
	if E.clicked:
		await C.player.face_clicked()
	
	await C.player.say("I have nothing to say about that")


## Called when `E.current_command == Commands.PULL` and E.command_fallback()
## is triggered.
func pull() -> void:
	C.player.say("I don't want to pull that")


## Called when `E.current_command == Commands.GIVE` and E.command_fallback()
## is triggered.
func give() -> void:
	C.player.say("What?")


## Called when `E.current_command == Commands.TALK_TO` and E.command_fallback()
## is triggered.
func talk_to() -> void:
	C.player.say("Emmmm...")


## Called when `E.current_command == Commands.USE` and E.command_fallback()
## is triggered.
func use() -> void:
	C.player.say("What?")
