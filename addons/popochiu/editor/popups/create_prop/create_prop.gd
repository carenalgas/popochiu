# Allows you to create a new Prop for a room.
# 
# If it has interaction, it will be assigned a script that will be saved in the
# prop's folder.
@tool
extends 'res://addons/popochiu/editor/popups/creation_popup.gd'

const Helper := preload("res://addons/popochiu/editor/helpers/popochiu_prop_helper.gd")
const TabRoom := preload("res://addons/popochiu/editor/main_dock/tab_room.gd")

var room_tab: VBoxContainer = null

var _room: Node2D = null
var _new_prop_name := ''
var _helper: PopochiuPropHelper

@onready var _interaction_checkbox: CheckBox = find_child('InteractionCheckbox')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	super()
	_clear_fields()
	
	_interaction_checkbox.toggled.connect(_interaction_toggled)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _create() -> void:
	if _new_prop_name.is_empty():
		_error_feedback.show()
		return

	_helper = Helper.new()
	_helper.init(_main_dock.ei, room_tab)

	var prop_instance = _helper.create(_new_prop_name, _room, _interaction_checkbox.button_pressed)

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Abrir las propiedades de la prop creada en el Inspector
	_main_dock.fs.scan()
	await get_tree().create_timer(0.1).timeout
	_main_dock.ei.edit_node(prop_instance)
	_main_dock.ei.select_file(prop_instance.scene_file_path)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Fin
	hide()


func _clear_fields() -> void:
	_new_prop_name = ''
	_interaction_checkbox.button_pressed = false


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func room_opened(r: Node2D) -> void:
	_room = r


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_new_prop_name = _name.to_snake_case()

		_update_info()
		_info.show()
	else:
		_info.clear()
		_info.hide()


func _interaction_toggled(is_pressed: bool) -> void:
	if is_pressed and not _name.is_empty():
		_update_info()
	else:
		_info.clear()


func _update_info() -> void:
	_info.text = (
		'In [b]%s[/b] the following file will be created:\n[code]%s[/code]' \
		% [
			_room.scene_file_path.get_base_dir(),
			'prop_' + _new_prop_name + '.gd'
		]
	)
