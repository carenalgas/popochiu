class_name NineVerbCommands
extends PopochiuCommands
## Defines the commands and fallback methods for the 9 Verbs GUI.
##
## In this GUI, players can use one of four commands to interact with objects: Walk, Open, Pick up,
## Push, Close, Look at, Pull, Give, Talk to, and Use. This behavior is based on games like The
## Secret of Monkey Island, Day of the Tentacle and Thimbleweed Park.

enum Commands { ## Defines the commands of the GUI.
	WALK_TO, ## Used when players want to make the PC to walk.
	OPEN, ## Used when players want to make the PC to open an object.
	PICK_UP, ## Used when players want to make the PC to pick up an object.
	PUSH, ## Used when players want to make the PC to push an object.
	CLOSE, ## Used when players want to make the PC to close an object.
	LOOK_AT, ## Used when players want to make the PC to look an object.
	PULL, ## Used when players want to make the PC to pull an object.
	GIVE, ## Used when players want to make the PC to give an object.
	TALK_TO, ## Used when players want to make the PC to talk to an object.
	USE ## Used when players want to make the PC to use an object.
}


#region Godot ######################################################################################
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


#endregion

#region Public #####################################################################################
static func get_script_name() -> String:
	return "NineVerbCommands"


## Called by [Popochiu] when a command doesn't have an associated [Callable]. By default this calls
## [method walk_to].
func fallback() -> void:
	walk_to()


## Called when [code]E.current_command == Commands.WALK_TO[/code] and
## [code]E.command_fallback()[/code] is triggered.[br][br]
## By default makes the character walk to the clicked [code]PopochiuClickable[/code].
func walk_to() -> void:
#	E.get_node("/root/C").walk_to_clicked()
	if I.active:
		I.active = null
		return
	
	C.player.walk_to_clicked()
	
	await C.player.move_ended
	
	if (
		E.clicked and E.clicked.get("suggested_command")
		and E.clicked.last_click_button == MOUSE_BUTTON_RIGHT
	):
		E.current_command = E.clicked.suggested_command
		E.clicked.handle_command(MOUSE_BUTTON_LEFT)


## Called when [code]E.current_command == Commands.OPEN[/code] and [code]E.command_fallback()[/code]
## is triggered.
func open() -> void:
	await C.player.say("Can't open that")


## Called when [code]E.current_command == Commands.PICK_UP[/code] and
## [code]E.command_fallback()[/code] is triggered.
func pick_up() -> void:
	await C.player.say("Not picking that up")


## Called when [code]E.current_command == Commands.PUSH[/code] and [code]E.command_fallback()[/code]
## is triggered.
func push() -> void:
	await C.player.say("I don't want to push that")


## Called when [code]E.current_command == Commands.CLOSE[/code] and
## [code]E.command_fallback()[/code] is triggered.
func close() -> void:
	await C.player.say("Can't close that")


## Called when [code]E.current_command == Commands.LOOK_AT[/code] and
## [code]E.command_fallback()[/code] is triggered.
func look_at() -> void:
	if E.clicked:
		await C.player.face_clicked()
	
	await C.player.say("I have nothing to say about that")


## Called when [code]E.current_command == Commands.PULL[/code] and [code]E.command_fallback()[/code]
## is triggered.
func pull() -> void:
	await C.player.say("I don't want to pull that")


## Called when [code]E.current_command == Commands.GIVE[/code] and [code]E.command_fallback()[/code]
## is triggered.
func give() -> void:
	await _give_or_use(give_item_to)


## Called when [code]E.current_command == Commands.USE[/code] and [code]E.command_fallback()[/code]
## is triggered.
func use() -> void:
	await _give_or_use(use_item_on)


func _give_or_use(callback: Callable) -> void:
	if I.active and E.clicked:
		callback.call(I.active, E.clicked)
	elif I.active and I.clicked and I.active != I.clicked:
		callback.call(I.active, I.clicked)
	elif I.clicked:
		match I.clicked.last_click_button:
			MOUSE_BUTTON_LEFT:
				I.clicked.set_active(true)
			MOUSE_BUTTON_RIGHT:
				# TODO: I'm not sure this is the right way to do this. Maybe GUIs should capture
				# 		click inputs on clickables and inventory items. ----------------------------
				E.current_command = (
					I.clicked.suggested_command if I.clicked.get("suggested_command")
					else Commands.LOOK_AT
				)
				
				I.clicked.handle_command(MOUSE_BUTTON_LEFT)
				# ----------------------------------------------------------------------------------
	else:	
		await C.player.say("What?")


## Called when [code]E.current_command == Commands.TALK_TO[/code] and
## [code]E.command_fallback()[/code] is triggered.
func talk_to() -> void:
	await C.player.say("Emmmm...")


func use_item_on(_item: PopochiuInventoryItem, _target: Node) -> void:
	I.active = null
	await C.player.say("I don't want to do that")


func give_item_to(_item: PopochiuInventoryItem, _target: Node) -> void:
	I.active = null
	await C.player.say("I don't want to do that")

#endregion
