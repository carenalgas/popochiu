extends PopochiuPopup

@onready var sound_volumes: GridContainer = %SoundVolumes


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	# Connect to singletons signals
	G.sound_settings_requested.connect(open)


#endregion

#region Virtual ####################################################################################
func _open() -> void:
	sound_volumes.update_sliders()


func _on_cancel() -> void:
	sound_volumes.restore_last_volumes()


#endregion
