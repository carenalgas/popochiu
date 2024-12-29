class_name SierraCommands
extends PopochiuCommands
## Defines the commands and fallback methods for the Sierra GUI.
##
## In this GUI, players can use one of four commands to interact with objects: Walk, Look, Interact
## and Talk. This behavior is based on the one used in King's Quest VI and Conquests of the Longbow.

enum Commands { ## Defines the commands of the GUI.
	WALK, ## Used when players want to make the PC to walk.
	LOOK, ## Used when players want to make the PC to look an object.
	INTERACT, ## Used when players want to make the PC to interact with an object.
	TALK ## Used when players want to make the PC to talk with an object.
}


#region Godot ######################################################################################
func _init() -> void:
	super()
	
	PopochiuUtils.e.register_command(Commands.WALK, "Walk", walk)
	PopochiuUtils.e.register_command(Commands.LOOK, "Look", look)
	PopochiuUtils.e.register_command(Commands.INTERACT, "Interact", interact)
	PopochiuUtils.e.register_command(Commands.TALK, "Talk", talk)


#endregion

#region Public #####################################################################################
## Should return the name of this class, or the identifier you want to use in scripts to know the
## type of the current GUI commands.
static func get_script_name() -> String:
	return "SierraCommands"


## Called by [Popochiu] when a command doesn't have an associated [Callable]. By default this calls
## [method walk].
func fallback() -> void:
	walk()


## Called when [code]E.current_command == Commands.WALK[/code] and [code]E.command_fallback()[/code]
## is triggered.[br]
## By default makes the character walk to the clicked [PopochiuClickable].
func walk() -> void:
	if PopochiuUtils.e.clicked:
		PopochiuUtils.c.walk_to_clicked()


## Called when [code]E.current_command == Commands.LOOK[/code] and [code]E.command_fallback()[/code]
## is triggered.
func look() -> void:
	PopochiuUtils.g.show_system_text(
		"%s has nothing to say about that object" % PopochiuUtils.c.player.description
	)


## Called when [code]E.current_command == Commands.INTERACT[/code] and
## [code]E.command_fallback()[/code] is triggered.
func interact() -> void:
	if (
		(PopochiuUtils.i.active and PopochiuUtils.i.clicked)
		and PopochiuUtils.i.active != PopochiuUtils.i.clicked
	):
		# Item used on another item
		PopochiuUtils.g.show_system_text("%s can't use %s with %s" % [
			PopochiuUtils.c.player.description,
			PopochiuUtils.i.active.description,
			PopochiuUtils.i.clicked.description
		])
	elif PopochiuUtils.i.active and PopochiuUtils.e.clicked:
		# Item used on a PopochiuClickable
		PopochiuUtils.g.show_system_text("%s can't use %s with %s" % [
			PopochiuUtils.c.player.description,
			PopochiuUtils.i.active.description,
			PopochiuUtils.e.clicked.description
		])
	elif PopochiuUtils.i.clicked:
		# Item selected in inventory
		PopochiuUtils.i.clicked.set_active()
	else:
		# PopochiuClickable clicked
		PopochiuUtils.g.show_system_text(
			"%s doesn't want to do anything with that object" % PopochiuUtils.c.player.description
		)


## Called when [code]E.current_command == Commands.TALK[/code] and [code]E.command_fallback()[/code]
## is triggered.
func talk() -> void:
	PopochiuUtils.g.show_system_text("%s can't talk with that" % PopochiuUtils.c.player.description)


#endregion
