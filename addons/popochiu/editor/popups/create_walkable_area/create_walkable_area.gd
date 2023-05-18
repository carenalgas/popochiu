# Creates a new walkable area in a room.
@tool
extends 'res://addons/popochiu/editor/popups/creation_popup.gd'

const SCRIPT_TEMPLATE :=\
'res://addons/popochiu/engine/templates/walkable_area_template.gd'
const WALKABLE_AREA_SCENE :=\
'res://addons/popochiu/engine/objects/walkable_area/popochiu_walkable_area.tscn'
const Constants := preload('res://addons/popochiu/popochiu_resources.gd')
const TabRoom := preload("res://addons/popochiu/editor/main_dock/tab_room.gd")

var room_tab: VBoxContainer = null

var _room: Node2D = null
var _new_walkable_area_name := ''
var _new_walkable_area_path := ''
var _walkable_area_path_template := ''
var _room_path := ''
var _room_dir := ''
var _pascal_name := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	super()
	_clear_fields()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _create() -> void:
	if _new_walkable_area_name.is_empty():
		_error_feedback.show()
		return

	# TODO: Check if another WalkableArea was created in the same PATH.
	# TODO: Remove created files if the creation process failed.
	var script_path := _new_walkable_area_path + '.gd'
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the folder for the WalkableArea
	assert(
		DirAccess.make_dir_recursive_absolute(
			_new_walkable_area_path.get_base_dir()
		) == OK,
		'[Popochiu] Could not create walkable_area folder for '\
		+ _new_walkable_area_name
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the script for the WalkableArea
	var walkable_area_template := load(SCRIPT_TEMPLATE)
	if ResourceSaver.save(walkable_area_template, script_path) != OK:
		push_error(
			"[Popochiu] Couldn't create script: %s.gd" % _new_walkable_area_name
		)
		# TODO: Show feedback in the popup
		return

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the new WalkableArea and add it to the room
	var walkable_area: PopochiuWalkableArea = ResourceLoader.load(
		WALKABLE_AREA_SCENE
	).instantiate()
	walkable_area.set_script(ResourceLoader.load(script_path))
	walkable_area.name = _pascal_name
	walkable_area.script_name = _pascal_name
	walkable_area.description = _new_walkable_area_name.capitalize()
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the NavigationRegion2D (instead of using the one that
	# was part of the original scene)
	var perimeter := NavigationRegion2D.new()
	walkable_area.add_child(perimeter)
	perimeter.name = 'Perimeter'
	
	var polygon := NavigationPolygon.new()
	polygon.add_outline(PackedVector2Array([
		Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)
	]))
	polygon.make_polygons_from_outlines()
	
	perimeter.navpoly = polygon
	perimeter.modulate = Color.GREEN
	
	# Attach the walkable area to the room
	_room.get_node('WalkableAreas').add_child(walkable_area)
	
	# Make the room the owner of both the Node2D and its NavigationRegion2D
	walkable_area.owner = _room
	perimeter.owner = _room
	
	walkable_area.position = Vector2(
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH),
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	) / 2.0
	
	_main_dock.ei.save_scene()
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Update the list of WalkableAreas in the Room tab
	(room_tab as TabRoom).add_to_list(
		Constants.Types.WALKABLE_AREA,
		_pascal_name,
		script_path
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Abrir las propiedades de la walkable area creada en el Inspector
	await get_tree().create_timer(0.1).timeout
	_main_dock.ei.edit_node(walkable_area)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Fin
	hide()

		
func _clear_fields() -> void:
	super()
	
	_new_walkable_area_name = ''
	_new_walkable_area_path = ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func room_opened(r: Node2D) -> void:
	_room = r
	_room_path = _room.scene_file_path
	_room_dir = _room_path.get_base_dir()
	_walkable_area_path_template = _room_dir +\
	'/walkable_areas/%s/walkable_area_%s'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_new_walkable_area_name = _name.to_snake_case()
		_pascal_name = _name
		_new_walkable_area_path = _walkable_area_path_template %\
		[_new_walkable_area_name, _new_walkable_area_name]

		_info.text = (
			'In [b]%s[/b] the following files will be created:\n[code]%s[/code]'\
			% [
				_room_dir + '/walkable_areas',
				'walkable_area_' + _new_walkable_area_name + '.gd'
			]
		)
		_info.show()
	else:
		_info.clear()
		_info.hide()
