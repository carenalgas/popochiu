# Creates a PopochiuInventoryItem.
# 
# It creates all the necessary files to make a PopochiuInventoryItem to work and
# to store its state:
# - InventoryXXX.tsn
# - InventoryXXX.gd
# - InventoryXXX.tres
# - InventoryXXXState.gd
@tool
extends 'res://addons/popochiu/editor/popups/creation_popup.gd'

const INVENTORY_ITEM_STATE_TEMPLATE :=\
'res://addons/popochiu/engine/templates/inventory_item_state_template.gd'
const INVENTORY_ITEM_SCRIPT_TEMPLATE := \
'res://addons/popochiu/engine/templates/inventory_item_template.gd'
const BASE_INVENTORY_ITEM_PATH := \
'res://addons/popochiu/engine/objects/inventory_item/popochiu_inventory_item.tscn'
const Constants := preload('res://addons/popochiu/popochiu_resources.gd')
const PopochiuDock :=\
preload('res://addons/popochiu/editor/main_dock/popochiu_dock.gd')

var _new_item_name := ''
var _new_item_path := ''
var _item_path_template := ''
var _pascal_name := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	super()
	_clear_fields()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _create() -> void:
	if _new_item_name.is_empty():
		_error_feedback.show()
		return
	
	# TODO: Check that there is not an inventory item in the same PATH.
	# TODO: Delete created files if something fails.
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the folder for the item
	DirAccess.make_dir_absolute(_main_dock.INVENTORY_ITEMS_PATH + _new_item_name)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the state Resource for the item and a script so devs
	# can add extra properties to that state
	var state_template: Script = load(INVENTORY_ITEM_STATE_TEMPLATE)
	if ResourceSaver.save(state_template, _new_item_path + '_state.gd') != OK:
		push_error(
			"[Popochiu] Couldn't create item state script: %s" %\
			_new_item_name
		)
		# TODO: Show feedback in the popup
		return
	
	var item_resource: PopochiuInventoryItemData =\
	load(_new_item_path + '_state.gd').new()
	item_resource.script_name = _pascal_name
	item_resource.scene = _new_item_path + '.tscn'
	item_resource.resource_name = _pascal_name
	
	if ResourceSaver.save(item_resource, _new_item_path + '.tres') != OK:
		push_error(
			"[Popochiu] Couldn't create PopochiuInventoryItemData for item: %s"\
			% _new_item_name
		)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the script for the item
	var item_script: Script = load(INVENTORY_ITEM_SCRIPT_TEMPLATE)
	var new_code := item_script.source_code
	
	item_script.source_code = ''
	
	if ResourceSaver.save(item_script, _new_item_path + '.gd') != OK:
		push_error('[Popochiu] Could not create script: %s.gd' % _new_item_name)
		# TODO: Show feedback in the popup
		return
	
	new_code = new_code.replace(
		'inventory_item_state_template',
		'item_%s_state' % _new_item_name
	)
	
	new_code = new_code.replace(
		'Data = null',
		"Data = load('%s.tres')" % _new_item_path
	)
	
	item_script = load(_new_item_path + '.gd')
	item_script.source_code = new_code
	
	if ResourceSaver.save(item_script, _new_item_path + '.gd') != OK:
		push_error('[Popochiu] Could not update script: %s.gd' % _new_item_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the item instance
	var new_item: PopochiuInventoryItem =\
	preload(BASE_INVENTORY_ITEM_PATH).instantiate()
	# 	The script is assigned first so that other properties will not be
	# 	overwritten by that assignment.
	new_item.set_script(load(_new_item_path + '.gd'))
	
	new_item.name = 'Item' + _new_item_name
	new_item.script_name = _pascal_name
	new_item.description = _pascal_name.capitalize()
	new_item.cursor = Constants.CURSOR_TYPE.USE
	new_item.size_flags_vertical = new_item.SIZE_SHRINK_CENTER
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Save the item scene (.tscn)
	var new_item_packed_scene: PackedScene = PackedScene.new()
	new_item_packed_scene.pack(new_item)
	if ResourceSaver.save(new_item_packed_scene, _new_item_path + '.tscn') != OK:
		push_error('[Popochiu] Could not create item: %s.tscn' % _new_item_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Add the created inventory item to Popochiu's inventory_items list
	if _main_dock.add_resource_to_popochiu(
		'inventory_items', ResourceLoader.load(_new_item_path + '.tres')
	) != OK:
		push_error(
			"[Popochiu] Couldn't add the created inventory item to Popochiu: %s"\
			% _new_item_name
		)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Add the inventory item to the I singleton
	PopochiuResources.update_autoloads(true)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Update the list of inventory items in the dock
	(_main_dock as PopochiuDock).add_to_list(
		Constants.Types.INVENTORY_ITEM, _pascal_name
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Open the scene in the editor
	await get_tree().create_timer(0.1).timeout
	_main_dock.ei.select_file(_new_item_path + '.tscn')
	_main_dock.ei.open_scene_from_path(_new_item_path + '.tscn')
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# That's all!!!!!!!
	hide()


func _clear_fields() -> void:
	_new_item_name = ''
	_new_item_path = ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func set_main_dock(node: Panel) -> void:
	super(node)
	
	if not _main_dock: return
	
	# res://popochiu/inventory_items/
	_item_path_template = _main_dock.INVENTORY_ITEMS_PATH + '%s/item_%s'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_new_item_name = _name.to_snake_case()
		_pascal_name = _name
		_new_item_path = _item_path_template %\
		[_new_item_name, _new_item_name]

		_info.text = (
			'In [b]%s[/b] the following files will be created:\
			\n[code]%s, %s and %s[/code]' \
			% [
				_main_dock.INVENTORY_ITEMS_PATH + _new_item_name,
				'item_' + _new_item_name + '.tscn',
				'item_' + _new_item_name + '.gd',
				'item_' + _new_item_name + '.tres'
			]
		)
		_info.show()
	else:
		_info.clear()
		_info.hide()
