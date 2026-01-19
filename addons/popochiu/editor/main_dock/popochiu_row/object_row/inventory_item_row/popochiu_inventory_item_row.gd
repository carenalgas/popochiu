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
	
	# Connect to the menu's about_to_popup signal to update the menu state dynamically
	menu_popup.about_to_popup.connect(_update_menu_state)


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
## Called before the context menu is shown. Updates the menu state based on the current inventory
## configuration, particularly checking if the inventory limit has been reached.
func _update_menu_state() -> void:
	var items: Array = PopochiuConfig.get_inventory_items_on_start()
	var script_name := str(name)
	var inventory_limit := PopochiuConfig.get_inventory_limit()
	
	# Get the menu item index for the "Start with it" option
	var start_with_it_idx := menu_popup.get_item_index(InventoryItemOptions.START_WITH_IT)

	# Check if we've reached the inventory limit
	# The option should be disabled if:
	# - The inventory limit is set (> 0)
	# - The limit has been reached
	# - The current item is not already in the starting inventory
	var should_disable := (
		inventory_limit > 0
		and items.size() >= inventory_limit
		and script_name not in items
	)
	
	# Enable or disable the menu item accordingly
	menu_popup.set_item_disabled(start_with_it_idx, should_disable)
	# Add a tooltip to inform the user why the option is disabled
	menu_popup.set_item_tooltip(
		start_with_it_idx,
		("You have reached the inventory size limit set in Popochiu Config (%d)." % inventory_limit)
			if should_disable
			else ""
	)


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


func _remove_from_core(should_save_and_delete := true) -> void:
	# Delete the object from Popochiu
	PopochiuResources.remove_autoload_obj(PopochiuResources.I_SNGL, name)
	PopochiuResources.erase_data_value("inventory_items", str(name))
	
	# Continue with the deletion flow
	super()


#endregion
