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
	_command_when_opened = PopochiuUtils.e.current_command
	PopochiuUtils.e.current_command = -1
	
	for button: TextureButton in %CommandsContainer.get_children():
		button.set_pressed_no_signal(false)


func _close() -> void:
	if PopochiuUtils.i.active:
		PopochiuUtils.cursor.set_secondary_cursor_texture(PopochiuUtils.i.active.texture)
		PopochiuUtils.cursor.hide_main_cursor()
	else:
		if PopochiuUtils.e.current_command == -1:
			PopochiuUtils.e.current_command = _command_when_opened
		
		PopochiuUtils.cursor.show_cursor(PopochiuUtils.e.get_current_command_name().to_snake_case())


#endregion

#region Private ####################################################################################
func _on_interact_pressed() -> void:
	_select_command(SierraCommands.Commands.INTERACT)


func _on_look_pressed() -> void:
	_select_command(SierraCommands.Commands.LOOK)


func _on_talk_pressed() -> void:
	_select_command(SierraCommands.Commands.TALK)


func _select_command(command: int) -> void:
	if is_instance_valid(PopochiuUtils.i.active):
		PopochiuUtils.i.active = null
	
	PopochiuUtils.e.current_command = command
	
	# Force changing the cursor passing `true` as second parameter
	PopochiuUtils.cursor.show_cursor(PopochiuUtils.e.get_current_command_name().to_snake_case(), true)


#endregion
