@tool
extends PopochiuPopup

@onready var sound_volumes: GridContainer = %SoundVolumes


#region Virtual ####################################################################################
func _open() -> void:
	sound_volumes.update_sliders()


func _on_cancel() -> void:
	sound_volumes.restore_last_volumes()
	# Unpause gameplay
	get_tree().paused = false


func _on_ok() -> void:
	# Unpause gameplay
	get_tree().paused = false

#endregion
