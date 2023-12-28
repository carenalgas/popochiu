# Creates a new hotspot in the room.
@tool
extends 'res://addons/popochiu/editor/popups/creation_popup.gd'

## TODO: remove this legacy...
var room_tab: VBoxContainer = null

var _room: Node2D = null
var _new_hotspot_name := ''
var _factory: PopochiuHotspotFactory


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	super()
	_clear_fields()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _create() -> void:
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Setup the region helper and use it to create the hotspot
	_factory = PopochiuHotspotFactory.new(_main_dock)

	if _factory.create(_new_hotspot_name, _room) != ResultCodes.SUCCESS:
		# TODO: show a message in the popup!
		return

	var hotspot = _factory.get_obj_scene()

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Open the properties of the created region in the inspector
	# Done here because the creation is interactive in this case
	await get_tree().create_timer(0.1).timeout
	PopochiuEditorHelper.select_node(hotspot)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# End
	hide()



func _clear_fields() -> void:
	_new_hotspot_name = ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func room_opened(r: Node2D) -> void:
	_room = r


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_new_hotspot_name = _name.to_snake_case()

		_info.text = (
			'In [b]%s[/b] the following file will be created:\n[code]%s[/code]'\
			% [
				_room.scene_file_path.get_base_dir() + '/hotspots',
				'hotspot_' + _new_hotspot_name + '.gd'
			]
		)
		_info.show()
	else:
		_info.clear()
		_info.hide()
