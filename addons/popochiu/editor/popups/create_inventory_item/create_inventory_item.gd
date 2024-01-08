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

# TODO: Giving a proper class name to PopochiuDock eliminates the need to preload it
# and to cast it as the right type later in code.
const PopochiuDock := preload('res://addons/popochiu/editor/main_dock/popochiu_dock.gd')

var _new_item_name := ''
var _factory: PopochiuInventoryItemFactory


#region Godot ######################################################################################
func _ready() -> void:
	super()
	_clear_fields()


#endregion

#region Virtual ####################################################################################
func _create() -> void:
	if _new_item_name.is_empty():
		_error_feedback.show()
		return
	
	# Setup the prop helper and use it to create the prop ------------------------------------------
	_factory = PopochiuInventoryItemFactory.new(_main_dock)

	if _factory.create(_new_item_name) != ResultCodes.SUCCESS:
		# TODO: show a message in the popup!
		return
	var item_scene = _factory.get_obj_scene()
	
	# Open the scene in the editor -----------------------------------------------------------------
	await get_tree().create_timer(0.1).timeout
	EditorInterface.select_file(item_scene.scene_file_path)
	EditorInterface.open_scene_from_path(item_scene.scene_file_path)
	
	hide()


func _clear_fields() -> void:
	_new_item_name = ''


#endregion

#region SetGet #####################################################################################
func set_main_dock(node: Panel) -> void:
	super(node)
	
	if not _main_dock: return


#endregion

#region Private ####################################################################################
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_new_item_name = _name.to_snake_case()

		_info.text = (
			'In [b]%s[/b] the following files will be created:\
			\n[code]- %s\n- %s\n- %s[/code]' \
			% [
				_main_dock.INVENTORY_ITEMS_PATH + _new_item_name,
				'inventory_item_' + _new_item_name + '.tscn',
				'inventory_item_' + _new_item_name + '.gd',
				'inventory_item_' + _new_item_name + '.tres'
			]
		)
		_info.show()
	else:
		_info.clear()
		_info.hide()
	
	_update_size_and_position()


#endregion
