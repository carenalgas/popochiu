extends PanelContainer

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


func _input(event: InputEvent) -> void:
	# TODO: This was `if D.current_dialog:`. Check if everything works as expected
	if G.is_blocked: return
	
	if event is InputEventMouseMotion:
		var rect := get_rect()
		
		if E.settings.scale_gui:
			rect = Rect2(
				get_rect().position * E.scale,
				(Vector2(
					get_rect().size.x,
					get_rect().size.y if visible else get_rect().size.y / 2.0
				)) * E.scale
			)
		
		if not visible and rect.has_point(get_global_mouse_position()):
			# Show the top menu
			if not I.active:
				Cursor.show_cursor("gui")
			
			show()
		elif visible and not rect.has_point(get_global_mouse_position()):
			# Hide the top menu
			if not I.active:
				Cursor.show_cursor(E.get_current_command_name().to_snake_case())
			
			hide()


#endregion

#region Private ####################################################################################
func _on_inventory_pressed() -> void:
	hide()
	G.popup_requested.emit("SierraInventoryPopup")


func _on_settings_pressed() -> void:
	hide()
	G.popup_requested.emit("SierraSettingsPopup")


func _on_help_pressed() -> void:
	# TODO: Open the help popup
	pass


func _on_quit_pressed() -> void:
	G.popup_requested.emit("QuitPopup")


#endregion
