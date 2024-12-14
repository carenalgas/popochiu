extends Control

## Defines the height in pixels of the zone where moving the mouse in the top of the screen will
## make the bar to show. Note: This value will be affected by the Experimental Scale GUI checkbox
## in Project Settings > Popochiu > GUI.
@export var input_zone_height := 4

@onready var panel_container: PanelContainer = $PanelContainer
@onready var inventory = %Inventory
@onready var settings = %Settings
@onready var help = %Help
@onready var quit = %Quit


#region Godot ######################################################################################
func _ready():
	inventory.pressed.connect(_on_inventory_pressed)
	settings.pressed.connect(_on_settings_pressed)
	help.pressed.connect(_on_help_pressed)
	quit.pressed.connect(_on_quit_pressed)
	
	hide()


func _input(event: InputEvent) -> void:
	if PopochiuUtils.g.is_blocked: return
	
	if event is InputEventMouseMotion:
		var rect := panel_container.get_rect()
		
		if not visible:
			rect.size.y = input_zone_height
		
		if PopochiuUtils.e.settings.scale_gui:
			rect = Rect2(
				panel_container.get_rect().position * PopochiuUtils.e.scale,
				(Vector2(
					panel_container.get_rect().size.x,
					panel_container.get_rect().size.y if visible
					else panel_container.get_rect().size.y / 2.0
				)) * PopochiuUtils.e.scale
			)
		
		if not visible and rect.has_point(get_global_mouse_position()):
			# Show the top menu
			if not PopochiuUtils.i.active:
				PopochiuUtils.cursor.show_cursor("gui")
			show()
		elif visible and not rect.has_point(get_global_mouse_position()):
			# Hide the top menu
			if not PopochiuUtils.i.active:
				PopochiuUtils.cursor.show_cursor(PopochiuUtils.e.get_current_command_name().to_snake_case())
			hide()


#endregion

#region Private ####################################################################################
func _on_inventory_pressed() -> void:
	hide()
	PopochiuUtils.g.popup_requested.emit("SierraInventoryPopup")


func _on_settings_pressed() -> void:
	hide()
	PopochiuUtils.g.popup_requested.emit("SierraSettingsPopup")


func _on_help_pressed() -> void:
	# TODO: Open the help popup
	pass


func _on_quit_pressed() -> void:
	PopochiuUtils.g.popup_requested.emit("QuitPopup")


#endregion
