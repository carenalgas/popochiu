#class_name CustomCommands
extends PopochiuCommands

enum Commands {
	#X_RAY, POWERFUL_HAND, HYPER_SCREAM
}


func _init() -> void:
	super()
	
	#E.register_command(Commands.X_RAY, "x ray", x_ray)
	#E.register_command(Commands.POWERFUL_HAND, "powerful hand", powerful_hand)
	#E.register_command(Commands.HYPER_SCREAM, "hyper scream", hyper_scream)


static func get_script_name() -> String:
	return "CustomCommands"


func fallback() -> void:
	super()


#func x_ray()-> void:
	#pass
#
#
#func powerful_hand()-> void:
	#pass
#
#
#func hyper_scream()-> void:
	#pass
