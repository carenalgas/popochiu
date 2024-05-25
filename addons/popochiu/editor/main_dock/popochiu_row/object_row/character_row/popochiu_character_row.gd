@tool
extends "res://addons/popochiu/editor/main_dock/popochiu_row/object_row/popochiu_object_row.gd"

enum CharacterOptions {
	DELETE = MenuOptions.DELETE,
	ADD_TO_CORE = Options.ADD_TO_CORE,
	SET_AS_PC,
}

const TAG_ICON = preload("res://addons/popochiu/icons/player_character.png")
const STATE_TEMPLATE = "res://addons/popochiu/engine/templates/character_state_template.gd"

var is_pc := false : set = set_is_pc


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	# Assign icons
	tag.texture = TAG_ICON


#endregion

#region Virtual ####################################################################################
func _get_state_template() -> Script:
	return load(STATE_TEMPLATE)


func _clear_tag() -> void:
	if is_pc:
		is_pc = false


#endregion

#region SetGet #####################################################################################
func set_is_pc(value: bool) -> void:
	is_pc = value
	
	if is_pc:
		PopochiuEditorHelper.signal_bus.pc_changed.emit(name)
	
	tag.visible = value
	menu_popup.set_item_disabled(menu_popup.get_item_index(CharacterOptions.SET_AS_PC), value)


#endregion

#region Private ####################################################################################
func _get_menu_cfg() -> Array:
	return [
		{
			id = CharacterOptions.SET_AS_PC,
			icon = TAG_ICON,
			label = "Set as Player-controlled Character (PC)",
		},
	] + super()


func _menu_item_pressed(id: int) -> void:
	match id:
		CharacterOptions.SET_AS_PC:
			self.is_pc = true
		_:
			super(id)


func _remove_from_core() -> void:
	# Delete the object from Popochiu
	PopochiuResources.remove_autoload_obj(PopochiuResources.C_SNGL, name)
	PopochiuResources.erase_data_value("characters", str(name))
	
	# Continue with the deletion flow
	super()


#endregion
