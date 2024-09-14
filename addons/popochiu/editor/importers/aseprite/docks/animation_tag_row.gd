@tool
extends HBoxContainer

signal tag_state_changed

const RESULT_CODE = preload("res://addons/popochiu/editor/config/result_codes.gd")

var _anim_tag_state: Dictionary = {}

@onready var tag_name_label = $HBoxContainer/TagName
@onready var import_toggle = $Panel/HBoxContainer/Import
@onready var loops_toggle = $Panel/HBoxContainer/Loops
@onready var separator = $Panel/HBoxContainer/Separator
@onready var visible_toggle = $Panel/HBoxContainer/Visible
@onready var clickable_toggle = $Panel/HBoxContainer/Clickable


#region Godot ######################################################################################
func _ready():
	# Common toggle icons
	import_toggle.icon = get_theme_icon('Load', 'EditorIcons')
	loops_toggle.icon = get_theme_icon('Loop', 'EditorIcons')
	# Room-related toggle icons
	visible_toggle.icon = get_theme_icon('GuiVisibilityVisible', 'EditorIcons')
	clickable_toggle.icon = get_theme_icon('ToolSelect', 'EditorIcons')


#endregion

#region Public #####################################################################################
func init(tag_cfg: Dictionary):
	if tag_cfg.tag_name == null or tag_cfg.tag_name == "":
		printerr(RESULT_CODE.get_error_message(RESULT_CODE.ERR_UNNAMED_TAG_DETECTED))
		return false
	
	_anim_tag_state = _load_default_tag_state()
	_anim_tag_state.merge(tag_cfg, true)
	_setup_scene()

func show_prop_buttons():
	separator.visible = true
	visible_toggle.visible =  true
	clickable_toggle.visible = true


#endregion

#region SetGet #####################################################################################
func get_cfg() -> Dictionary:
	return _anim_tag_state


#endregion

#region Private ####################################################################################
func _setup_scene():
	import_toggle.button_pressed = _anim_tag_state.import
	loops_toggle.button_pressed = _anim_tag_state.loops
	tag_name_label.text = _anim_tag_state.tag_name
	visible_toggle.button_pressed = _anim_tag_state.prop_visible
	clickable_toggle.button_pressed = _anim_tag_state.prop_clickable
	emit_signal("tag_state_changed")


func _load_default_tag_state() -> Dictionary:
	return {
		"tag_name": "",
		"import": PopochiuConfig.is_default_animation_import_enabled(),
		"loops": PopochiuConfig.is_default_animation_loop_enabled(),
		"prop_visible": PopochiuConfig.is_default_animation_prop_visible(),
		"prop_clickable": PopochiuConfig.is_default_animation_prop_clickable(),
	}


func _on_import_toggled(button_pressed):
	_anim_tag_state.import = button_pressed
	emit_signal("tag_state_changed")


func _on_loops_toggled(button_pressed):
	_anim_tag_state.loops = button_pressed
	emit_signal("tag_state_changed")


func _on_visible_toggled(button_pressed):
	_anim_tag_state.prop_visible = button_pressed
	emit_signal("tag_state_changed")

func _on_clickable_toggled(button_pressed):
	_anim_tag_state.prop_clickable = button_pressed
	emit_signal("tag_state_changed")


#endregion
