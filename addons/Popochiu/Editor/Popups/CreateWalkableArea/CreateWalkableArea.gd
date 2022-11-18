tool
extends 'res://addons/Popochiu/Editor/Popups/CreationPopup.gd'
# Creates a new walkable area in a room

const SCRIPT_TEMPLATE := 'res://addons/Popochiu/Engine/Templates/WalkableAreaTemplate.gd'
const WALKABLE_AREA_SCENE := 'res://addons/Popochiu/Engine/Objects/WalkableArea/PopochiuWalkableArea.tscn'
const Constants := preload('res://addons/Popochiu/PopochiuResources.gd')

var room_tab: VBoxContainer = null

var _room: Node2D = null
var _new_walkable_area_name := ''
var _new_walkable_area_path := ''
var _walkable_area_path_template: String
var _room_path: String
var _room_dir: String


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	_clear_fields()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func set_main_dock(node: PopochiuDock) -> void:
	.set_main_dock(node)


func room_opened(r: Node2D) -> void:
	_room = r
	_room_path = _room.filename
	_room_dir = _room_path.get_base_dir()
	_walkable_area_path_template = _room_dir + '/WalkableAreas/%s/WalkableArea%s'


func create() -> void:
	if not _new_walkable_area_name:
		_error_feedback.show()
		return

	# TODO: Check if another WalkableArea was created in the same PATH.
	# TODO: Remove created files if the creation process failed.
	var script_path := _new_walkable_area_path + '.gd'
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the folder for the WalkableArea
	assert(
		_main_dock.dir.make_dir_recursive(_new_walkable_area_path.get_base_dir()) == OK,
		'[Popochiu] Could not create WalkableArea folder for ' + _new_walkable_area_name
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the script for the WalkableArea
	var walkable_area_template := load(SCRIPT_TEMPLATE)
	if ResourceSaver.save(script_path, walkable_area_template) != OK:
		push_error('[Popochiu] Could not create script: %s.gd' % _new_walkable_area_name)
		# TODO: Show feedback in the popup
		return

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the new WalkableArea and add it to the room
	var walkable_area: PopochiuWalkableArea = ResourceLoader.load(WALKABLE_AREA_SCENE).instance()
	walkable_area.set_script(ResourceLoader.load(script_path))
	walkable_area.name = _new_walkable_area_name
	walkable_area.script_name = _new_walkable_area_name
	walkable_area.description = _new_walkable_area_name
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the NavigationPolygonInstance (instead of using the one that
	# was part of the original scene)
	var perimeter := NavigationPolygonInstance.new()
	walkable_area.add_child(perimeter)
	perimeter.name = 'Perimeter'
	
	var polygon := NavigationPolygon.new()
	polygon.add_outline(PoolVector2Array([
		Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)
	]))
	polygon.make_polygons_from_outlines()
	
	perimeter.navpoly = polygon
	perimeter.modulate = Color.green
	
	# Attach the walkable area to the room
	_room.get_node('WalkableAreas').add_child(walkable_area)
	
	# FIX: Make the room the owner of both the Navigation2D and its
	# NavigationPolygonInstance
	walkable_area.owner = _room
	perimeter.owner = _room
	
	walkable_area.position = Vector2(
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH),
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	) / 2.0
	
	_main_dock.ei.save_scene()
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Update the list of WalkableAreas in the Room tab
	room_tab.add_to_list(
		Constants.Types.WALKABLE_AREA,
		_new_walkable_area_name,
		script_path
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Abrir las propiedades de la walkable area creada en el Inspector
	yield(get_tree().create_timer(0.1), 'timeout')
	_main_dock.ei.edit_node(walkable_area)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Fin
	hide()

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_name(new_text: String) -> void:
	._update_name(new_text)

	if _name:
		_new_walkable_area_name = _name
		_new_walkable_area_path = _walkable_area_path_template %\
		[_new_walkable_area_name, _new_walkable_area_name]

		_info.bbcode_text = (
			'In [b]%s[/b] the following files will be created: [code]%s[/code]' \
			% [
				_room_dir + '/WalkableAreas',
				'WalkableArea' + _new_walkable_area_name + '.gd'
			]
		)
	else:
		_info.clear()

		
func _clear_fields() -> void:
	._clear_fields()
	
	_new_walkable_area_name = ''
	_new_walkable_area_path = ''
