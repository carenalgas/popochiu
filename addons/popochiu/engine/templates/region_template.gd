# @popochiu-docs-ignore-class
@tool
extends PopochiuRegion


#region Virtual ####################################################################################
func _on_character_entered(chr: PopochiuCharacter) -> void:
	# Put any logic here to run when a character enters the region.
	# By default, the region will apply its `tint` color to the character's sprite. You can replace
	# this with your own logic, or call `super(chr)` to preserve the default behavior, then add your
	# own.
	super(chr)


func _on_character_exited(chr: PopochiuCharacter) -> void:
	# Put any logic here to run when a character exits the region.
	# By default, the region will restore the color of the character's sprite. You can replace this
	# with your own logic, or call `super(chr)` to preserve the default behavior, then add your own.
	super(chr)

#endregion
