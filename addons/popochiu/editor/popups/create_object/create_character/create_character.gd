@tool
extends "res://addons/popochiu/editor/popups/create_object/create_object.gd"
## Creates a new [PopochiuCharacter].
##
## It creates all the necessary files to make a [PopochiuCharacter] to work and to
## store its state:
## - character_xxx.tscn
## - character_xxx.gd
## - character_xxx.tres
## - character_xxx_state.gd

var _new_character_name := ""
var _factory: PopochiuCharacterFactory
var _show_set_as_pc := false : set = set_show_set_as_pc

@onready var set_as_pc_panel: PanelContainer = %SetAsPCPanel
@onready var rtl_is_pc: RichTextLabel = %RtlIsPC
@onready var btn_is_pc: CheckBox = %BtnIsPC


#region Godot ######################################################################################
func _ready() -> void:
	_info_files = _info_files.replace("&t", "character")
	
	super()


#endregion

#region Virtual ####################################################################################
func _create() -> Object:
	if _new_character_name.is_empty():
		error_feedback.show()
		return null
	
	# Setup the prop helper and use it to create the prop ------------------------------------------
	_factory = PopochiuCharacterFactory.new()
	if _factory.create(_new_character_name, btn_is_pc.button_pressed) != ResultCodes.SUCCESS:
		# TODO: show a message in the popup!
		return null
	await get_tree().create_timer(0.1).timeout
	
	return _factory.get_obj_scene()


func _on_about_to_popup() -> void:
	PopochiuEditorHelper.override_font(rtl_is_pc, "normal_font", "main")
	PopochiuEditorHelper.override_font(rtl_is_pc, "bold_font", "bold")
	PopochiuEditorHelper.override_font(rtl_is_pc, "italics_font", "doc_italic")
	
	_check_if_has_pc()
	info.hide()


func _set_info_text() -> void:
	_new_character_name = _name.to_snake_case()
	_target_folder = PopochiuResources.CHARACTERS_PATH.path_join(_new_character_name)
	
	info.text = (_info_text % _target_folder).replace("&n", _new_character_name)


#endregion

#region SetGet #####################################################################################
func set_show_set_as_pc(value: bool) -> void:
	_show_set_as_pc = value
	
	if is_instance_valid(set_as_pc_panel):
		set_as_pc_panel.visible = _show_set_as_pc


#endregion

#region Private ####################################################################################
func _check_if_has_pc() -> void:
	# Display the checkbox if the game's PC has not been defined yet
	_show_set_as_pc = PopochiuResources.get_data_value("setup", "pc", "").is_empty()


#endregion
