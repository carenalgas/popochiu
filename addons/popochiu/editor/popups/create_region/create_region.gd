# Allows you to create a new Region for a room.

@tool
extends 'res://addons/popochiu/editor/popups/creation_popup.gd'

const Helper := preload("res://addons/popochiu/editor/helpers/popochiu_region_helper.gd")

## TODO: remove this legacy...
var room_tab: VBoxContainer = null

var _room: Node2D = null
var _new_region_name := ''
var _helper: PopochiuRegionHelper


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	super()
	_clear_fields()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _create() -> void:
	if _new_region_name.is_empty():
		_error_feedback.show()
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Setup the region helper and use it to create the region
	_helper = Helper.new()
	_helper.init(_main_dock)

	var region = _helper.create(_new_region_name, _room, false)

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Open the properties of the created region in the inspector
	# Done here because the creation is interactive in this case
	await get_tree().create_timer(0.1).timeout
	_main_dock.ei.edit_node(region)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# End
	hide()


func _clear_fields() -> void:
	_new_region_name = ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func room_opened(r: Node2D) -> void:
	_room = r


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_new_region_name = _name.to_snake_case()
		_info.text = (
			'In [b]%s[/b] the following files will be created:\n[code]%s[/code]' \
			% [
				_room.scene_file_path.get_base_dir() + '/regions',
				'region_' + _new_region_name + '.gd'
			]
		)
		_info.show()
	else:
		_info.clear()
		_info.hide()
