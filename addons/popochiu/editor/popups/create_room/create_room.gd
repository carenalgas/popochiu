@tool
extends 'res://addons/popochiu/editor/popups/creation_popup.gd'
## Creates a PopochiuRoom.
## 
## It creates all the necessary files to make a PopochiuRoom to work and
## to store its state:
## - RoomXXX.tsn
## - RoomXXX.gd
## - RoomXXX.tres
## - RoomXXXState.gd

# TODO: Giving a proper class name to PopochiuDock eliminates the need to preload it
# and to cast it as the right type later in code.
const PopochiuDock := preload('res://addons/popochiu/editor/main_dock/popochiu_dock.gd')

var show_set_as_main := false : set = _set_show_set_as_main

var _new_room_name := ''
var _factory: PopochiuRoomFactory

@onready var set_as_main_panel: PanelContainer = %SetAsMainPanel
@onready var btn_is_main: CheckBox = %BtnIsMain


#region Godot ######################################################################################
func _ready() -> void:
	super()
	about_to_popup.connect(_check_if_first_room)
	
	_clear_fields()
	set_as_main_panel.hide()


#endregion

#region Virtual ####################################################################################
func _create() -> void:
	if _new_room_name.is_empty():
		_error_feedback.show()
		return
	
	# Setup the prop helper and use it to create the prop ------------------------------------------
	_factory = PopochiuRoomFactory.new(_main_dock)

	if _factory.create(
		_new_room_name,
		btn_is_main.button_pressed
	) != ResultCodes.SUCCESS:
		# TODO: show a message in the popup!
		return

	var room_scene = _factory.get_obj_scene()
	
	# Open the scene in the editor -----------------------------------------------------------------
	await get_tree().create_timer(0.1).timeout
	EditorInterface.select_file(room_scene.scene_file_path)
	EditorInterface.open_scene_from_path(room_scene.scene_file_path)
	
	# That's all! ----------------------------------------------------------------------------------
	clear_fields()
	hide()


func _clear_fields() -> void:
	_new_room_name = ''
	btn_is_main.button_pressed = false


func _on_about_to_popup() -> void:
	PopochiuUtils.override_font(%RtlIsMain, 'normal_font', get_theme_font("main", "EditorFonts"))
	PopochiuUtils.override_font(%RtlIsMain, 'bold_font', get_theme_font("bold", "EditorFonts"))


#endregion

#region SetGet #####################################################################################
func set_main_dock(node: Panel) -> void:
	super(node)
	
	if not _main_dock: return
	

#endregion

#region Private ####################################################################################
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_new_room_name = _name.to_snake_case()

		_info.text = (
			'In [b]%s[/b] the following files will be created:\
			\n[code]- %s\n- %s\n- %s[/code]' \
			% [
				_main_dock.ROOMS_PATH + _new_room_name,
				'room_' + _new_room_name + '.tscn',
				'room_' + _new_room_name + '.gd',
				'room_' + _new_room_name + '.tres'
			]
		)
		_info.show()
	else:
		_info.clear()
		_info.hide()
	
	_update_size_and_position()


func _check_if_first_room() -> void:
	# Display a checkbox to set the room as the main scene of the project if it's the first created
	self.show_set_as_main = PopochiuResources.get_section('rooms').is_empty()


func _set_show_set_as_main(value: bool) -> void:
	show_set_as_main = value
	
	if not set_as_main_panel: return
	
	set_as_main_panel.visible = value


#endregion
