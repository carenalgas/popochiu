extends 'res://addons/popochiu/editor/helpers/popochiu_room_obj_base_helper.gd'
class_name PopochiuWalkableAreaHelper

const BASE_SCRIPT_TEMPLATE := 'res://addons/popochiu/engine/templates/walkable_area_template.gd'
const BASE_OBJ_PATH := 'res://addons/popochiu/engine/objects/walkable_area/popochiu_walkable_area.tscn'

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func init(_main_dock: Panel) -> void:
	super(_main_dock)
	_obj_path_template = '/walkable_areas/%s/walkable_area_%s'


func create(obj_name: String, room: PopochiuRoom) -> PopochiuWalkableArea:
	_open_room(room)
	_setup_name(obj_name)

	# TODO: Check if another WalkableArea was created in the same PATH.
	# TODO: Remove created files if the creation process failed.
	var script_path := _obj_path + '.gd'
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the folder for the WalkableArea
	assert(
		DirAccess.make_dir_recursive_absolute(
			_obj_path.get_base_dir()
		) == OK,
		'[Popochiu] Could not create walkable_area folder for '	+ _obj_name
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the script for the WalkableArea
	var obj_template := load(BASE_SCRIPT_TEMPLATE)
	
	if ResourceSaver.save(obj_template, script_path) != OK:
		push_error(
			"[Popochiu] Couldn't create script: %s.gd" % _obj_name
		)
		# TODO: Show feedback in the popup
		return

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the new WalkableArea and add it to the room
	var obj: PopochiuWalkableArea = ResourceLoader.load(BASE_OBJ_PATH).instantiate()
	obj.set_script(ResourceLoader.load(script_path))
	obj.name = _obj_name
	obj.script_name = _obj_name
	obj.description = _obj_script_name.capitalize()
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the NavigationRegion2D (instead of using the one that
	# was part of the original scene)
	var perimeter := NavigationRegion2D.new()
	obj.add_child(perimeter)
	perimeter.name = 'Perimeter'
	
	var polygon := NavigationPolygon.new()
	polygon.add_outline(PackedVector2Array([
		Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)
	]))
	polygon.make_polygons_from_outlines()
	
	perimeter.navpoly = polygon
	perimeter.modulate = Color.GREEN
	
	# Attach the walkable area to the room
	_room.get_node('WalkableAreas').add_child(obj)
	
	# Make the room the owner of both the Node2D and its NavigationRegion2D
	obj.owner = _room
	perimeter.owner = _room
	
	obj.position = Vector2(
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH),
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	) / 2.0
	
	_ei.save_scene()
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Update the list of WalkableAreas in the Room tab
	(_room_tab as TabRoom).add_to_list(
		Constants.Types.WALKABLE_AREA,
		_obj_name,
		script_path
	)

	return obj
