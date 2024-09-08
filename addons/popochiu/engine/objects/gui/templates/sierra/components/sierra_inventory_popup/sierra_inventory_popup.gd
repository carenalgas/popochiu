@tool
extends PopochiuPopup

var _command_when_opened: int = -1

@onready var interact: TextureButton = %Interact
@onready var look: TextureButton = %Look
@onready var talk: TextureButton = %Talk


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	interact.pressed.connect(_on_interact_pressed)
	look.pressed.connect(_on_look_pressed)
	talk.pressed.connect(_on_talk_pressed)


#endregion

#region Virtual ####################################################################################
func _open() -> void:
	_command_when_opened = E.current_command
	E.current_command = -1
	
	for button: TextureButton in %CommandsContainer.get_children():
		button.set_pressed_no_signal(false)


func _close() -> void:
	if I.active:
		Cursor.set_secondary_cursor_texture(I.active.texture)
		Cursor.hide_main_cursor()
	else:
		if E.current_command == -1:
			E.current_command = _command_when_opened
		
		Cursor.show_cursor(E.get_current_command_name().to_snake_case())


#endregion

#region Private ####################################################################################
func _on_interact_pressed() -> void:
	_select_command(SierraCommands.Commands.INTERACT)


func _on_look_pressed() -> void:
	_select_command(SierraCommands.Commands.LOOK)


func _on_talk_pressed() -> void:
	_select_command(SierraCommands.Commands.TALK)


func _select_command(command: int) -> void:
	if is_instance_valid(I.active):
		I.active = null
	
	E.current_command = command
	
	# Force changing the cursor passing `true` as second parameter
	Cursor.show_cursor(E.get_current_command_name().to_snake_case(), true)


#endregion
