tool
extends 'res://addons/Popochiu/Editor/Popups/CreationPopup.gd'
# Allows to create a new PopochiuInventoryItem with the files required for its
# operation within Popochiu and to store its state:
#   Inventory???.tsn, Inventory???.gd, Inventory???.tres and Inventory???State.gd
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

const INVENTORY_ITEM_STATE_TEMPLATE :=\
'res://addons/Popochiu/Engine/Templates/InventoryItemStateTemplate.gd'
const INVENTORY_ITEM_SCRIPT_TEMPLATE := \
'res://addons/Popochiu/Engine/Templates/InventoryItemTemplate.gd'
const BASE_INVENTORY_ITEM_PATH := \
'res://addons/Popochiu/Engine/Objects/InventoryItem/PopochiuInventoryItem.tscn'
const Constants := preload('res://addons/Popochiu/PopochiuResources.gd')

var _new_item_name := ''
var _new_item_path := ''
var _item_path_template: String


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	_clear_fields()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func set_main_dock(node: PopochiuDock) -> void:
	.set_main_dock(node)
	# res://popochiu/InventoryItems/
	_item_path_template = _main_dock.INVENTORY_ITEMS_PATH + '%s/Inventory%s'


func create() -> void:
	if not _new_item_name:
		_error_feedback.show()
		return
	
	# TODO: Check that there is not a room in the same PATH.
	# TODO: Delete created files if creation is not complete.
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the folder for the item
	_main_dock.dir.make_dir(_main_dock.INVENTORY_ITEMS_PATH + _new_item_name)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the state Resource for the item and a script so devs
	# can add extra properties to that state
	var state_template: Script = load(INVENTORY_ITEM_STATE_TEMPLATE)
	if ResourceSaver.save(_new_item_path + 'State.gd', state_template) != OK:
		push_error('[Popochiu] Could not create item state script: %s' %\
		_new_item_name)
		# TODO: Show feedback in the popup
		return
	
	var item_resource: PopochiuInventoryItemData =\
	load(_new_item_path + 'State.gd').new()
	item_resource.script_name = _new_item_name
	item_resource.scene = _new_item_path + '.tscn'
	item_resource.resource_name = _new_item_name
	
	if ResourceSaver.save(_new_item_path + '.tres',\
	item_resource) != OK:
		push_error(\
		'[Popochiu] Could not create PopochiuInventoryItemData for item: %s' %\
		_new_item_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the script for the item
	var item_template := load(INVENTORY_ITEM_SCRIPT_TEMPLATE)
	if ResourceSaver.save(_new_item_path + '.gd', item_template) != OK:
		push_error('[Popochiu] Could not create script: %s.gd' % _new_item_name)
		# TODO: Show feedback in the popup
		return
	
	# Assign the state to the item
	var item_script: Script = load(_new_item_path + '.gd')
	item_script.source_code = item_script.source_code.replace(
		'PopochiuInventoryItemData = null',
		"PopochiuInventoryItemData = preload('Inventory%s.tres')" % _new_item_name
	)
	ResourceSaver.save(_new_item_path + '.gd', item_script)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the item instance
	var new_item: PopochiuInventoryItem =\
	preload(BASE_INVENTORY_ITEM_PATH).instance()
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
	if ResourceSaver.save(_new_item_path + '.tscn', new_item_packed_scene) != OK:
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
	# Update the list of characters in the dock
	_main_dock.add_to_list(Constants.Types.INVENTORY_ITEM, _new_item_name)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Open the scene in the editor
	yield(get_tree().create_timer(0.1), 'timeout')
	_main_dock.ei.select_file(_new_item_path + '.tscn')
	_main_dock.ei.open_scene_from_path(_new_item_path + '.tscn')
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# That's all!!!!!!!
	hide()

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_name(new_text: String) -> void:
	._update_name(new_text)

	if _name:
		_new_item_name = _name
		_new_item_path = _item_path_template %\
		[_new_item_name, _new_item_name]

		_info.bbcode_text = (
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
	._clear_fields()
	
	_new_item_name = ''
	_new_item_path = ''
