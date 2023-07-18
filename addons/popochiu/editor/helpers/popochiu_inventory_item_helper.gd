extends 'res://addons/popochiu/editor/helpers/popochiu_obj_base_helper.gd'
class_name PopochiuInventoryItemHelper

const BASE_STATE_TEMPLATE := 'res://addons/popochiu/engine/templates/inventory_item_state_template.gd'
const BASE_SCRIPT_TEMPLATE := 'res://addons/popochiu/engine/templates/inventory_item_template.gd'
const BASE_OBJ_PATH := 'res://addons/popochiu/engine/objects/inventory_item/popochiu_inventory_item.tscn'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func init(_main_dock: Panel) -> void:
	super(_main_dock)
	_obj_path_template = _main_dock.INVENTORY_ITEMS_PATH + '%s/item_%s'



func create(obj_name: String) -> PopochiuInventoryItem:
	# TODO: Check if another Prop was created in the same PATH.
	# TODO: Remove created files if the creation process failed.
	_setup_name(obj_name)

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the folder for the item
	DirAccess.make_dir_absolute(_main_dock.INVENTORY_ITEMS_PATH + _obj_script_name)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the state Resource for the item and a script so devs can add extra
	# properties to that state
	var state_template: Script = load(BASE_STATE_TEMPLATE).duplicate()
	if ResourceSaver.save(state_template, _obj_path + '_state.gd') != OK:
		push_error('[Popochiu] Could not create item state script: %s' %_obj_name)
		# TODO: Show feedback in the popup
		return

	var obj_resource: PopochiuInventoryItemData = load(_obj_path + '_state.gd').new()
	obj_resource.script_name = _obj_name
	obj_resource.scene = _obj_path + '.tscn'
	obj_resource.resource_name = _obj_name
	
	if ResourceSaver.save(obj_resource, _obj_path + '.tres') != OK:
		push_error("[Popochiu] Couldn't create PopochiuInventoryItemData for item: %s" % _obj_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the script for the item
	var obj_script: Script = load(BASE_SCRIPT_TEMPLATE).duplicate()
	var new_code := obj_script.source_code
	
	obj_script.source_code = ''
	
	if ResourceSaver.save(obj_script, _obj_path + '.gd') != OK:
		push_error("[Popochiu] Couldn't create script: %s" % _obj_name)
		# TODO: Show feedback in the popup
		return
	
	new_code = new_code.replace(
		'inventory_item_state_template',
		'item_%s_state' % _obj_script_name
	)
	
	new_code = new_code.replace(
		'Data = null',
		"Data = load('%s.tres')" % _obj_path
	)
	
	obj_script = load(_obj_path + '.gd')
	obj_script.source_code = new_code

	if ResourceSaver.save(obj_script, _obj_path + '.gd') != OK:
		push_error('[Popochiu] Could not update script: %s' % _obj_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the item instance
	var obj: PopochiuInventoryItem = load(BASE_OBJ_PATH).instantiate()
	
	# 	The script is assigned first so that other properties will not be
	# 	overwritten by that assignment.
	obj.set_script(load(_obj_path + '.gd'))
	
	obj.name = 'Item' + _obj_name
	obj.script_name = _obj_name
	obj.description = _obj_name.capitalize()
	obj.cursor = Constants.CURSOR_TYPE.USE
	obj.size_flags_vertical = obj.SIZE_SHRINK_CENTER
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Save the item scene (.tscn)
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(obj)
	if ResourceSaver.save(packed_scene, _obj_path + '.tscn') != OK:
		push_error("[Popochiu] Couldn't create item: %s" % _obj_name)
		# TODO: Show feedback in the popup
		return

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Load the scene to be returned to the calling code
	# Instancing the created .tscn file fixes #58
	var obj_instance: PopochiuInventoryItem = load(_obj_path + '.tscn').instantiate()


	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Add the created item to Popochiu's inventory items list
	if _main_dock.add_resource_to_popochiu(
		'inventory_items', ResourceLoader.load(_obj_path + '.tres')
	) != OK:
		push_error("[Popochiu] Couldn't add the created inventory item to Popochiu: %s" % _obj_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Add the item to the C singleton
	PopochiuResources.update_autoloads(true)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Update the list of inventory items in the dock
	var row := (_main_dock as MainDock).add_to_list(
		Constants.Types.INVENTORY_ITEM, _obj_name
	)
	
	return obj_instance
