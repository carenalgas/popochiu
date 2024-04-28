# Allows you to create a new Region for a room.

@tool
extends 'res://addons/popochiu/editor/popups/creation_popup.gd'

## TODO: remove this legacy...
var room_tab: VBoxContainer = null

var _room: Node2D = null
var _new_region_name := ''
var _factory: PopochiuRegionFactory


#region Godot ######################################################################################
func _ready() -> void:
	super()
	_clear_fields()


#endregion

#region Virtual ####################################################################################
func _create() -> void:
	if _new_region_name.is_empty():
		_error_feedback.show()
		return
	
	# Setup the region helper and use it to create the region --------------------------------------
	_factory = PopochiuRegionFactory.new(_main_dock)

	if _factory.create(_new_region_name, _room) != ResultCodes.SUCCESS:
		# TODO: show a message in the popup!
		return

	var region = _factory.get_obj_scene()

	# Open the properties of the created region in the inspector -----------------------------------
	# Done here because the creation is interactive in this case
	await get_tree().create_timer(0.1).timeout
	PopochiuEditorHelper.select_node(region)
	
	hide()


func _clear_fields() -> void:
	_new_region_name = ''


#endregion

#region Public #####################################################################################
func room_opened(r: Node2D) -> void:
	_room = r


#endregion

#region Private ####################################################################################
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
	
	_update_size_and_position()


#endregion
