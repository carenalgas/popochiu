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
	
	PopochiuUtils.e.register_command(Commands.WALK_TO, "Walk to", walk_to)
	PopochiuUtils.e.register_command(Commands.OPEN, "Open", open)
	PopochiuUtils.e.register_command(Commands.PICK_UP, "Pick up", pick_up)
	PopochiuUtils.e.register_command(Commands.PUSH, "Push", push)
	PopochiuUtils.e.register_command(Commands.CLOSE, "Close", close)
	PopochiuUtils.e.register_command(Commands.LOOK_AT, "Look at", look_at)
	PopochiuUtils.e.register_command(Commands.PULL, "Pull", pull)
	PopochiuUtils.e.register_command(Commands.GIVE, "Give", give)
	PopochiuUtils.e.register_command(Commands.TALK_TO, "Talk to", talk_to)
	PopochiuUtils.e.register_command(Commands.USE, "Use", use)


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
	if PopochiuUtils.i.active:
		PopochiuUtils.i.active = null
		return
	
	PopochiuUtils.c.player.walk_to_clicked()
	
	await PopochiuUtils.c.player.move_ended
	
	if (
		PopochiuUtils.e.clicked and PopochiuUtils.e.clicked.get("suggested_command")
		and PopochiuUtils.e.clicked.last_click_button == MOUSE_BUTTON_RIGHT
	):
		PopochiuUtils.e.current_command = PopochiuUtils.e.clicked.suggested_command
		PopochiuUtils.e.clicked.handle_command(MOUSE_BUTTON_LEFT)


## Called when [code]E.current_command == Commands.OPEN[/code] and [code]E.command_fallback()[/code]
## is triggered.
func open() -> void:
	await PopochiuUtils.c.player.say("Can't open that")


## Called when [code]E.current_command == Commands.PICK_UP[/code] and
## [code]E.command_fallback()[/code] is triggered.
func pick_up() -> void:
	await PopochiuUtils.c.player.say("Not picking that up")


## Called when [code]E.current_command == Commands.PUSH[/code] and [code]E.command_fallback()[/code]
## is triggered.
func push() -> void:
	await PopochiuUtils.c.player.say("I don't want to push that")


## Called when [code]E.current_command == Commands.CLOSE[/code] and
## [code]E.command_fallback()[/code] is triggered.
func close() -> void:
	await PopochiuUtils.c.player.say("Can't close that")


## Called when [code]E.current_command == Commands.LOOK_AT[/code] and
## [code]E.command_fallback()[/code] is triggered.
func look_at() -> void:
	if PopochiuUtils.e.clicked:
		await PopochiuUtils.c.player.face_clicked()
	
	await PopochiuUtils.c.player.say("I have nothing to say about that")


## Called when [code]E.current_command == Commands.PULL[/code] and [code]E.command_fallback()[/code]
## is triggered.
func pull() -> void:
	await PopochiuUtils.c.player.say("I don't want to pull that")


## Called when [code]E.current_command == Commands.GIVE[/code] and [code]E.command_fallback()[/code]
## is triggered.
func give() -> void:
	await _give_or_use(give_item_to)


## Called when [code]E.current_command == Commands.USE[/code] and [code]E.command_fallback()[/code]
## is triggered.
func use() -> void:
	await _give_or_use(use_item_on)


func _give_or_use(callback: Callable) -> void:
	if PopochiuUtils.i.active and PopochiuUtils.e.clicked:
		callback.call(PopochiuUtils.i.active, PopochiuUtils.e.clicked)
	elif (
		PopochiuUtils.i.active
		and PopochiuUtils.i.clicked
		and PopochiuUtils.i.active != PopochiuUtils.i.clicked
	):
		callback.call(PopochiuUtils.i.active, PopochiuUtils.i.clicked)
	elif PopochiuUtils.i.clicked:
		match PopochiuUtils.i.clicked.last_click_button:
			MOUSE_BUTTON_LEFT:
				PopochiuUtils.i.clicked.set_active(true)
			MOUSE_BUTTON_RIGHT:
				# TODO: I'm not sure this is the right way to do this. Maybe GUIs should capture
				# 		click inputs on clickables and inventory items. ----------------------------
				PopochiuUtils.e.current_command = (
					PopochiuUtils.i.clicked.suggested_command
					if PopochiuUtils.i.clicked.get("suggested_command")
					else Commands.LOOK_AT
				)
				
				PopochiuUtils.i.clicked.handle_command(MOUSE_BUTTON_LEFT)
				# ----------------------------------------------------------------------------------
	else:	
		await PopochiuUtils.c.player.say("What?")


## Called when [code]E.current_command == Commands.TALK_TO[/code] and
## [code]E.command_fallback()[/code] is triggered.
func talk_to() -> void:
	await PopochiuUtils.c.player.say("Emmmm...")


func use_item_on(_item: PopochiuInventoryItem, _target: Node) -> void:
	PopochiuUtils.i.active = null
	await PopochiuUtils.c.player.say("I don't want to do that")


func give_item_to(_item: PopochiuInventoryItem, _target: Node) -> void:
	PopochiuUtils.i.active = null
	await PopochiuUtils.c.player.say("I don't want to do that")

#endregion
