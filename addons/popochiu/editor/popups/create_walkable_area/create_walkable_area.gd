# Creates a new walkable area in a room.
@tool
extends 'res://addons/popochiu/editor/popups/creation_popup.gd'

const Helper := preload("res://addons/popochiu/editor/helpers/popochiu_walkable_area_helper.gd")

## TODO: remove this legacy...
var room_tab: VBoxContainer = null

var _room: Node2D = null
var _new_walkable_area_name := ''
var _helper: PopochiuWalkableAreaHelper


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	super()
	_clear_fields()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _create() -> void:
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Setup the region helper and use it to create the region
	_helper = Helper.new()
	_helper.init(_main_dock)

	var walkable_area = _helper.create(_new_walkable_area_name, _room)

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Open the properties of the created region in the inspector
	# Done here because the creation is interactive in this case
	await get_tree().create_timer(0.1).timeout
	_main_dock.ei.edit_node(walkable_area)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# End
	hide()

		
func _clear_fields() -> void:
	super()
	
	_new_walkable_area_name = ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func room_opened(r: Node2D) -> void:
	_room = r


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_new_walkable_area_name = _name.to_snake_case()

		_info.text = (
			'In [b]%s[/b] the following files will be created: [code]%s[/code]'\
			% [
				_room.scene_file_path.get_base_dir() + '/walkable_areas',
				'walkable_area_' + _new_walkable_area_name + '.gd'
			]
		)
		_info.show()
	else:
		_info.clear()
		_info.hide()
