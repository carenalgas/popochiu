# Creates a PopochiuInventoryItem.
# 
# It creates all the necessary files to make a PopochiuInventoryItem to work and
# to store its state:
# - InventoryXXX.tsn
# - InventoryXXX.gd
# - InventoryXXX.tres
# - InventoryXXXState.gd
@tool
extends 'res://addons/Popochiu/Editor/Popups/CreationPopup.gd'

const INVENTORY_ITEM_STATE_TEMPLATE :=\
'res://addons/Popochiu/Engine/Templates/InventoryItemStateTemplate.gd'
const INVENTORY_ITEM_SCRIPT_TEMPLATE := \
'res://addons/Popochiu/Engine/Templates/InventoryItemTemplate.gd'
const BASE_INVENTORY_ITEM_PATH := \
'res://addons/Popochiu/Engine/Objects/InventoryItem/PopochiuInventoryItem.tscn'
const Constants := preload('res://addons/Popochiu/PopochiuResources.gd')
const PopochiuDock :=\
preload('res://addons/Popochiu/Editor/MainDock/PopochiuDock.gd')

var _new_item_name := ''
var _new_item_path := ''
var _item_path_template: String


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	super()
	_clear_fields()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func set_main_dock(node: Panel) -> void:
	super(node)
	
	# res://popochiu/InventoryItems/
	_item_path_template = _main_dock.INVENTORY_ITEMS_PATH + '%s/Inventory%s'


func create() -> void:
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
	if ResourceSaver.save(state_template, _new_item_path + 'State.gd') != OK:
		push_error('[Popochiu] Could not create item state script: %s' %\
		_new_item_name)
		# TODO: Show feedback in the popup
		return
	
	var item_resource: PopochiuInventoryItemData =\
	load(_new_item_path + 'State.gd').new()
	item_resource.script_name = _new_item_name
	item_resource.scene = _new_item_path + '.tscn'
	item_resource.resource_name = _new_item_name
	
	if ResourceSaver.save(item_resource, _new_item_path + '.tres') != OK:
		push_error(\
		'[Popochiu] Could not create PopochiuInventoryItemData for item: %s' %\
		_new_item_name)
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
		'InventoryItemStateTemplate',
		'Inventory%sState' % _new_item_name
	)
	
	new_code = new_code.replace(
		'Data = null',
		"Data = preload('Inventory%s.tres')" % _new_item_name
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
	new_item.script_name = _new_item_name
	new_item.description = _new_item_name.capitalize()
	new_item.cursor = Constants.CURSOR_TYPE.USE
	new_item.name = 'Inventory' + _new_item_name
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
		push_error(\
		'[Popochiu] Could not add the created inventory item to Popochiu: %s' %\
		_new_item_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Add the inventory item to the I singleton
	PopochiuResources.update_autoloads(true)
	_main_dock.fs.update_script_classes()
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Update the list of inventory items in the dock
	_main_dock.add_to_list(Constants.Types.INVENTORY_ITEM, _new_item_name)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Open the scene in the editor
	await get_tree().create_timer(0.1).timeout
	_main_dock.ei.select_file(_new_item_path + '.tscn')
	_main_dock.ei.open_scene_from_path(_new_item_path + '.tscn')
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# That's all!!!!!!!
	hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_new_item_name = _name
		_new_item_path = _item_path_template %\
		[_new_item_name, _new_item_name]

		_info.text = (
			'In [b]%s[/b] the following files will be created:\n[code]%s, %s and %s[/code]' \
			% [
				_main_dock.INVENTORY_ITEMS_PATH + _new_item_name,
				'Inventory' + _new_item_name + '.tscn',
				'Inventory' + _new_item_name + '.gd',
				'Inventory' + _new_item_name + '.tres'
			]
		)
	else:
		_info.clear()


func _clear_fields() -> void:
	super()
	
	_new_item_name = ''
	_new_item_path = ''
