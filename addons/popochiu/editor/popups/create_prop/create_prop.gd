@tool
extends 'res://addons/popochiu/editor/popups/creation_popup.gd'
## Allows you to create a new Prop for a room.
## 
## If it has interaction, it will be assigned a script that will be saved in the
## prop's folder.

## TODO: remove this legacy...
#const TabRoom := preload("res://addons/popochiu/editor/main_dock/tab_room.gd")

## TODO: remove this legacy...
var room_tab: VBoxContainer = null

var _room: Node2D = null
var _new_prop_name := ''
var _factory: PopochiuPropFactory

@onready var _interaction_checkbox: CheckBox = find_child('InteractionCheckbox')


#region Godot ######################################################################################
func _ready() -> void:
	super()
	_clear_fields()
	
	_interaction_checkbox.toggled.connect(_interaction_toggled)


#endregion

#region Virtual ####################################################################################
func _create() -> void:
	if _new_prop_name.is_empty():
		_error_feedback.show()
		return

	# Setup the prop helper and use it to create the prop ------------------------------------------
	_factory = PopochiuPropFactory.new(_main_dock)

	if _factory.create(
		_new_prop_name, _room,
		_interaction_checkbox.button_pressed
	) != ResultCodes.SUCCESS:
		# TODO: show a message in the popup!
		return

	var prop_instance = _factory.get_obj_scene()

	# Open the properties of the created prop in the inspector -------------------------------------
	# Done here because the creation is interactive in this case
	EditorInterface.get_resource_filesystem().scan()
	
	await get_tree().create_timer(0.1).timeout
	
	EditorInterface.edit_node(prop_instance)
	EditorInterface.select_file(prop_instance.scene_file_path)
	
	hide()


func _clear_fields() -> void:
	_new_prop_name = ''
	_interaction_checkbox.button_pressed = false


#endregion

#region Public #####################################################################################
func room_opened(r: Node2D) -> void:
	_room = r


#endregion

#region Private ####################################################################################
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_new_prop_name = _name.to_snake_case()

		_update_info()
		_info.show()
	else:
		_info.clear()
		_info.hide()
	
	_update_size_and_position()


func _interaction_toggled(is_pressed: bool) -> void:
	if is_pressed and not _name.is_empty():
		_update_info()
	else:
		_info.clear()
	
	_update_size_and_position()


func _update_info() -> void:
	_info.text = (
		'In [b]%s[/b] the following file will be created:\n[code]%s[/code]' \
		% [
			_room.scene_file_path.get_base_dir() + '/props',
			'prop_' + _new_prop_name + '.gd'
		]
	)


#endregion
