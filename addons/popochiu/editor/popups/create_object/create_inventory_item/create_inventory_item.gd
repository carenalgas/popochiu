@tool
extends "res://addons/popochiu/editor/popups/create_object/create_object.gd"
## Creates a [PopochiuInventoryItem].
## 
## It creates all the necessary files to make a [PopochiuInventoryItem] to work and
## to store its state:
## - inventory_item_xxx.tscn
## - inventory_item_xxx.gd
## - inventory_item_xxx.tres
## - inventory_item_xxx_state.gd

var _new_item_name := ""
var _factory: PopochiuInventoryItemFactory


#region Godot ######################################################################################
func _ready() -> void:
	_info_files = _info_files.replace("&t", "inventory_item")
	
	super()


#endregion

#region Virtual ####################################################################################
func _create() -> Object:
	if _new_item_name.is_empty():
		error_feedback.show()
		return null
	
	# Setup the prop helper and use it to create the prop ------------------------------------------
	_factory = PopochiuInventoryItemFactory.new()
	if _factory.create(_new_item_name) != ResultCodes.SUCCESS:
		# TODO: show a message in the popup!
		return null
	await get_tree().create_timer(0.1).timeout
	
	return _factory.get_obj_scene()


func _set_info_text() -> void:
	_new_item_name = _name.to_snake_case()
	_target_folder = PopochiuResources.INVENTORY_ITEMS_PATH.path_join(_new_item_name)
	
	info.text = (_info_text % _target_folder).replace("&n", _new_item_name)


#endregion
