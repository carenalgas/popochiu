extends 'res://addons/popochiu/editor/helpers/popochiu_room_obj_base_helper.gd'
class_name PopochiuPropHelper

const BASE_SCRIPT_TEMPLATE := 'res://addons/popochiu/engine/templates/prop_template.gd'
const BASE_OBJ_PATH := 'res://addons/popochiu/engine/objects/prop/popochiu_prop.tscn'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func init(_main_dock: Panel) -> void:
	super(_main_dock)
	_obj_path_template = '/props/%s/prop_%s'


func create(obj_name: String, room: PopochiuRoom, is_interactive:bool = false) -> PopochiuProp:
	# TODO: Check if another Prop was created in the same PATH.
	# TODO: Remove created files if the creation process failed.
	_open_room(room)
	_setup_name(obj_name)

	var script_path := _obj_path + '.gd'
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the folder for the Prop
	assert(
		DirAccess.make_dir_recursive_absolute(_obj_path.get_base_dir()) == OK,
		'[Popochiu] Could not create prop folder for ' + _obj_script_name
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the script for the prop (if it has interaction)
	if is_interactive:
		var obj_template := load(BASE_SCRIPT_TEMPLATE)
		
		if ResourceSaver.save(obj_template, script_path) != OK:
			push_error(
				"[Popochiu] Couldn't create script: %s.gd" % _obj_script_name
			)
			# TODO: Show feedback in the popup
			return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the prop
	var obj: PopochiuProp = ResourceLoader.load(BASE_OBJ_PATH).instantiate()
	
	if is_interactive:
		obj.set_script(ResourceLoader.load(script_path))
	
	obj.name = _obj_name
	obj.script_name = _obj_name
	obj.description = _obj_script_name.capitalize()
	obj.clickable = is_interactive
	obj.cursor = Constants.CURSOR_TYPE.ACTIVE
	
	if _obj_script_name in ['bg', 'background']:
		obj.baseline =\
		-ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT) / 2.0
		obj.z_index = -1
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Save the prop scene (.tscn)
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(obj)
	if ResourceSaver.save(
		packed_scene, _obj_path + '.tscn'
	) != OK:
		push_error("[Popochiu] Couldn't create prop: %s.tscn" % _obj_script_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Add the prop to its room
	# Instancing the created .tscn file fixes #58
	var obj_instance: PopochiuProp = load(_obj_path + '.tscn').instantiate()
	
	_room.get_node('Props').add_child(obj_instance)
	
	obj_instance.owner = _room
	obj_instance.position = Vector2(
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH),
		ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	) / 2.0
	
	if is_interactive:
		var collision := CollisionPolygon2D.new()
		collision.name = 'InteractionPolygon'
		
		obj_instance.add_child(collision)
		collision.owner = _room
	
	_ei.save_scene()
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Update the list of Props in the Room tab
	(_room_tab as TabRoom).add_to_list(
		Constants.Types.PROP,
		_obj_name,
		_obj_path + '.tscn'
	)

	return obj_instance
