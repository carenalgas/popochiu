# Allows you to create a new Prop for a room.
# 
# If it has interaction, it will be assigned a script that will be saved in the
# prop's folder.
@tool
extends 'res://addons/popochiu/editor/popups/creation_popup.gd'

const PROP_SCRIPT_TEMPLATE :=\
'res://addons/popochiu/engine/templates/prop_template.gd'
const BASE_PROP_PATH :=\
'res://addons/popochiu/engine/objects/prop/popochiu_prop.tscn'
const Constants := preload('res://addons/popochiu/popochiu_resources.gd')
const TabRoom := preload("res://addons/popochiu/editor/main_dock/tab_room.gd")

var room_tab: VBoxContainer = null

var _room: Node2D = null
var _new_prop_name := ''
var _new_prop_path := ''
var _prop_path_template := ''
var _room_path := ''
var _room_dir := ''
var _pascal_name := ''

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
	
	# TODO: Check if another Prop was created in the same PATH.
	# TODO: Remove created files if the creation process failed.
	var script_path := _new_prop_path + '.gd'
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the folder for the Prop
	assert(
		DirAccess.make_dir_recursive_absolute(_new_prop_path.get_base_dir()) == OK,
		'[Popochiu] Could not create prop folder for ' + _new_prop_name
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the script for the prop (if it has interaction)
	if _interaction_checkbox.button_pressed:
		var prop_template := load(PROP_SCRIPT_TEMPLATE)
		
		if ResourceSaver.save(prop_template, script_path) != OK:
			push_error(
				"[Popochiu] Couldn't create script: %s.gd" % _new_prop_name
			)
			# TODO: Show feedback in the popup
			return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the prop
	var prop: PopochiuProp = ResourceLoader.load(BASE_PROP_PATH).instantiate()
	
	if _interaction_checkbox.button_pressed:
		prop.set_script(ResourceLoader.load(script_path))
	
	prop.name = _pascal_name
	prop.script_name = _pascal_name
	prop.description = _new_prop_name.capitalize()
	prop.clickable = _interaction_checkbox.button_pressed
	prop.cursor = Constants.CURSOR_TYPE.ACTIVE
	
	if _new_prop_name in ['Bg', 'Background']:
		prop.baseline =\
		-ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT) / 2.0
		prop.z_index = -1
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Save the prop scene (.tscn)
	var prop_packed_scene: PackedScene = PackedScene.new()
	prop_packed_scene.pack(prop)
	if ResourceSaver.save(
		prop_packed_scene, _new_prop_path + '.tscn'
	) != OK:
		push_error("[Popochiu] Couldn't create prop: %s.tscn" % _new_prop_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Add the prop to its room
	_room.get_node('Props').add_child(prop)
	
	prop.owner = _room
	prop.position = Vector2(
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH),
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	) / 2.0
	
	if _interaction_checkbox.button_pressed:
		var collision := CollisionPolygon2D.new()
		collision.name = 'InteractionPolygon'
		
		prop.add_child(collision)
		collision.owner = _room
	
	_main_dock.ei.save_scene()
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Update the list of Props in the Room tab
	(room_tab as TabRoom).add_to_list(
		Constants.Types.PROP,
		_pascal_name,
		_new_prop_path + '.tscn'
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Abrir las propiedades de la prop creada en el Inspector
	_main_dock.fs.scan()
	await get_tree().create_timer(0.1).timeout
	_main_dock.ei.edit_node(prop)
	
	_main_dock.ei.select_file(_new_prop_path + '.tscn')
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Fin
	hide()


func _clear_fields() -> void:
	_new_prop_name = ''
	_new_prop_path = ''
	_interaction_checkbox.button_pressed = false


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func room_opened(r: Node2D) -> void:
	_room = r
	_room_path = _room.scene_file_path
	_room_dir = _room_path.get_base_dir()
	_prop_path_template = _room_dir + '/props/%s/prop_%s'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_new_prop_name = _name.to_snake_case()
		_pascal_name = _name
		_new_prop_path = _prop_path_template % [_new_prop_name, _new_prop_name]

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
			_new_prop_path.get_base_dir(),
			'prop_' + _new_prop_name + '.gd'
		]
	)
