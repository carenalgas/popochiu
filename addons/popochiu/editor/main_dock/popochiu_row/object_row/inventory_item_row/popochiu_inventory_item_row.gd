@tool
extends "res://addons/popochiu/editor/main_dock/popochiu_row/object_row/popochiu_object_row.gd"

enum InventoryItemOptions {
	DELETE = MenuOptions.DELETE,
	ADD_TO_CORE = Options.ADD_TO_CORE,
	START_WITH_IT,
}

const TAG_ICON = preload("res://addons/popochiu/icons/inventory_item_start.png")
const STATE_TEMPLATE = "res://addons/popochiu/engine/templates/inventory_item_state_template.gd"

var is_on_start := false : set = set_is_on_start

#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	# Assign icons
	tag.texture = TAG_ICON


#endregion

#region Virtual ####################################################################################
func _get_state_template() -> Script:
	return load(STATE_TEMPLATE)


#endregion

#region SetGet #####################################################################################
func set_is_on_start(value: bool) -> void:
	is_on_start = value
	tag.visible = value


#endregion

#region Private ####################################################################################
func _get_menu_cfg() -> Array:
	return [
		{
			id = InventoryItemOptions.START_WITH_IT,
			icon = TAG_ICON,
			label = "Start with it",
		},
	] + super()


func _menu_item_pressed(id: int) -> void:
	match id:
		InventoryItemOptions.START_WITH_IT:
			var items: Array = PopochiuConfig.get_inventory_items_on_start()
			var script_name := str(name)
			
			if script_name in items:
				items.erase(script_name)
			else:
				items.append(script_name)
			
			PopochiuConfig.set_inventory_items_on_start(items)
			
			self.is_on_start = script_name in items
		_:
			super(id)


func _remove_from_core() -> void:
	# Delete the object from Popochiu
	PopochiuResources.remove_autoload_obj(PopochiuResources.I_SNGL, name)
	PopochiuResources.erase_data_value("inventory_items", str(name))
	
	# Continue with the deletion flow
	super()


#endregion
