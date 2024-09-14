@tool
extends PopochiuInventoryGrid

@onready var settings: TextureButton = %Settings


#region Godot ######################################################################################
func _ready():
	super()
	
	# Connect to child signals
	settings.pressed.connect(_on_settings_pressed)


#endregion

#region Private ####################################################################################
func _on_settings_pressed() -> void:
	G.gui.settings_requested.emit()


#endregion
