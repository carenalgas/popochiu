extends RefCounted
class_name PopochiuPropHelper

const PROP_SCRIPT_TEMPLATE := 'res://addons/popochiu/engine/templates/prop_template.gd'
const BASE_PROP_PATH := 'res://addons/popochiu/engine/objects/prop/popochiu_prop.tscn'
const Constants := preload('res://addons/popochiu/popochiu_resources.gd')
const TabRoom := preload("res://addons/popochiu/editor/main_dock/tab_room.gd")

var _room_tab: VBoxContainer = null
var _ei: EditorInterface

var _room: Node2D = null
var _prop_script_name := ''
var _prop_name := ''
var _prop_path := ''
var _prop_path_template := ''
var _room_path := ''
var _room_dir := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░

func init(ei: EditorInterface, room_tab: VBoxContainer) -> void:
	_ei = ei
	_room_tab = room_tab


func create(prop_name: String, room: PopochiuRoom, is_interactive:bool = false) -> PopochiuProp:
	# TODO: Check if another Prop was created in the same PATH.
	# TODO: Remove created files if the creation process failed.
	_open_room(room)
	_setup_name(prop_name)

	var script_path := _prop_path + '.gd'
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the folder for the Prop
	assert(
		DirAccess.make_dir_recursive_absolute(_prop_path.get_base_dir()) == OK,
		'[Popochiu] Could not create prop folder for ' + _prop_script_name
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the script for the prop (if it has interaction)
	if is_interactive:
		var prop_template := load(PROP_SCRIPT_TEMPLATE)
		
		if ResourceSaver.save(prop_template, script_path) != OK:
			push_error(
				"[Popochiu] Couldn't create script: %s.gd" % _prop_script_name
			)
			# TODO: Show feedback in the popup
			return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the prop
	var prop: PopochiuProp = ResourceLoader.load(BASE_PROP_PATH).instantiate()
	
	if is_interactive:
		prop.set_script(ResourceLoader.load(script_path))
	
	prop.name = _prop_name
	prop.script_name = _prop_name
	prop.description = _prop_script_name.capitalize()
	prop.clickable = is_interactive
	prop.cursor = Constants.CURSOR_TYPE.ACTIVE
	
	if _prop_script_name in ['bg', 'background']:
		prop.baseline =\
		-ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT) / 2.0
		prop.z_index = -1
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Save the prop scene (.tscn)
	var prop_packed_scene: PackedScene = PackedScene.new()
	prop_packed_scene.pack(prop)
	if ResourceSaver.save(
		prop_packed_scene, _prop_path + '.tscn'
	) != OK:
		push_error("[Popochiu] Couldn't create prop: %s.tscn" % _prop_script_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Add the prop to its room
	# Instancing the created .tscn file fixes #58
	var prop_instance: PopochiuProp = load(_prop_path + '.tscn').instantiate()
	
	_room.get_node('Props').add_child(prop_instance)
	
	prop_instance.owner = _room
	prop_instance.position = Vector2(
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH),
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	) / 2.0
	
	if is_interactive:
		var collision := CollisionPolygon2D.new()
		collision.name = 'InteractionPolygon'
		
		prop_instance.add_child(collision)
		collision.owner = _room
	
	_ei.save_scene()
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Update the list of Props in the Room tab
	(_room_tab as TabRoom).add_to_list(
		Constants.Types.PROP,
		_prop_name,
		_prop_path + '.tscn'
	)

	return prop_instance


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _open_room(room: PopochiuRoom) -> void:
	_room = room
	_room_path = _room.scene_file_path
	_room_dir = _room_path.get_base_dir()
	_prop_path_template = _room_dir + '/props/%s/prop_%s'


func _setup_name(prop_name: String) -> void:
	_prop_name = prop_name.to_pascal_case()
	_prop_script_name = prop_name.to_snake_case()
	_prop_path = _prop_path_template % [_prop_script_name, _prop_script_name]
