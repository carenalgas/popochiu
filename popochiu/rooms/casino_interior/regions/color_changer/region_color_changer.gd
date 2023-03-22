@tool
extends PopochiuRegion


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _on_character_entered(chr: PopochiuCharacter) -> void:
	# This is optional. You can put here anything you want to happen when a
	# character enters the area.
	chr.modulate = tint


func _on_character_exited(chr: PopochiuCharacter) -> void:
	# This is optional, too.
	chr.modulate = Color.WHITE
