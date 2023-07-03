extends 'res://addons/popochiu/editor/helpers/popochiu_obj_helper.gd'
class_name PopochiuHotspotHelper

const BASE_SCRIPT_TEMPLATE := 'res://addons/popochiu/engine/templates/hotspot_template.gd'
const BASE_OBJ_PATH := 'res://addons/popochiu/engine/objects/hotspot/popochiu_hotspot.tscn'

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func init(_main_dock: Panel) -> void:
	super(_main_dock)
	_obj_path_template = '/hotspots/%s/hotspot_%s'


func create(obj_name: String, room: PopochiuRoom, is_interactive:bool = false) -> PopochiuHotspot:
	_open_room(room)
	_setup_name(obj_name)

	# TODO: Check if another Hotspot was created in the same PATH.
	# TODO: Remove created files if the creation process failed.
	var script_path := _obj_path + '.gd'
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the folder for the Hotspot
	assert(
		DirAccess.make_dir_recursive_absolute(
			_obj_path.get_base_dir()
		) == OK,
		'[Popochiu] Could not create hotspot folder for '	+ _obj_name
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the script for the Hotspot
	var obj_template := load(BASE_SCRIPT_TEMPLATE)
	
	if ResourceSaver.save(obj_template, script_path) != OK:
		push_error(
			"[Popochiu] Couldn't create script: %s.gd" % _obj_name
		)
		# TODO: Show feedback in the popup
		return

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the new Hotspot and add it to the room
	var obj: PopochiuHotspot = ResourceLoader.load(BASE_OBJ_PATH).instantiate()
	obj.set_script(ResourceLoader.load(script_path))
	obj.name = _obj_name
	obj.script_name = _obj_name
	obj.description = _obj_script_name.capitalize()
	obj.cursor = Constants.CURSOR_TYPE.ACTIVE
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Attach the hotspot to the room
	_room.get_node('Hotspots').add_child(obj)
	
	# Make the room the owner of both the Node2D and its NavigationRegion2D
	obj.owner = _room
	obj.position = Vector2(
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH),
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	) / 2.0

	var collision := CollisionPolygon2D.new()
	collision.name = 'InteractionPolygon'
	obj.add_child(collision)
	collision.owner = _room
	collision.modulate = Color.BLUE

	_ei.save_scene()
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Update the list of Hotspots in the Room tab
	(_room_tab as TabRoom).add_to_list(
		Constants.Types.HOTSPOT,
		_obj_name,
		script_path
	)

	return obj
