@tool
extends HBoxContainer

signal tag_state_changed
signal tag_selected(tag_name)
signal request_delete_anim(tag_name)

const RESULT_CODE = preload("res://addons/popochiu/editor/config/result_codes.gd")

var _anim_tag_state: Dictionary = {}

var tag_name_label: Control
var import_toggle: Control
var loops_toggle: Control
var autoplays_toggle: Control
var separator: Control
var visible_toggle: Control
var clickable_toggle: Control
var delete_anim_button: Control

#region Public #####################################################################################
func init(tag_cfg: Dictionary):
	# Manually initialize node references if not already done
	# Used to be @onready var but it doesn't work because the
	# container gets repopulated without the script being reloaded.
	tag_name_label = $HBoxContainer/TagName
	import_toggle = $HBoxContainer/Panel/HBoxContainer/Import
	loops_toggle = $HBoxContainer/Panel/HBoxContainer/Loops
	autoplays_toggle = $HBoxContainer/Panel/HBoxContainer/Autoplays
	separator = $HBoxContainer/Panel/HBoxContainer/Separator
	visible_toggle = $HBoxContainer/Panel/HBoxContainer/Visible
	clickable_toggle = $HBoxContainer/Panel/HBoxContainer/Clickable
	delete_anim_button = $HBoxContainer/DeleteAnim
	
	# Set icons manually too:
	# 1. Common toggles icons
	import_toggle.icon = get_theme_icon('Load', 'EditorIcons')
	loops_toggle.icon = get_theme_icon('Loop', 'EditorIcons')
	autoplays_toggle.icon = get_theme_icon('AutoPlay', 'EditorIcons')
	# 2. Room-related toggles icons
	visible_toggle.icon = get_theme_icon('GuiVisibilityVisible', 'EditorIcons')
	clickable_toggle.icon = get_theme_icon('ToolSelect', 'EditorIcons')
	# 3. Delete animation icon
	delete_anim_button.icon = get_theme_icon('Remove', 'EditorIcons')
	
	# Connect tag name button pressed signal if not already connected
	if not tag_name_label.pressed.is_connected(_on_tag_name_pressed):
		tag_name_label.pressed.connect(_on_tag_name_pressed)

	# Connect delete button pressed signal if not already connectes
	if not delete_anim_button.pressed.is_connected(_on_delete_anim_pressed):
		delete_anim_button.pressed.connect(_on_delete_anim_pressed)

	# Continue with initialization
	if tag_cfg.tag_name == null or tag_cfg.tag_name == PopochiuEditorHelper.EMPTY_STRING:
		printerr(RESULT_CODE.get_error_message(RESULT_CODE.ERR_UNNAMED_TAG_DETECTED))
		return false
	
	_anim_tag_state = _load_default_tag_state()
	_anim_tag_state.merge(tag_cfg, true)
	_setup_scene()

func show_prop_buttons() -> void:
	separator.visible = true
	visible_toggle.visible =  true
	clickable_toggle.visible = true
	autoplays_toggle.visible = true

func show_inventory_item_buttons() -> void:
	separator.visible = true
	autoplays_toggle.visible = true


#endregion

#region SetGet #####################################################################################
func get_cfg() -> Dictionary:
	return _anim_tag_state


#endregion

#region Private ####################################################################################
func _setup_scene() -> void:
	tag_name_label.text = _anim_tag_state.tag_name
	import_toggle.set_pressed_no_signal(_anim_tag_state.import)
	loops_toggle.set_pressed_no_signal(_anim_tag_state.loops)
	autoplays_toggle.set_pressed_no_signal(_anim_tag_state.autoplays)
	visible_toggle.set_pressed_no_signal(_anim_tag_state.prop_visible)
	clickable_toggle.set_pressed_no_signal(_anim_tag_state.prop_clickable)
	emit_signal("tag_state_changed")


func _load_default_tag_state() -> Dictionary:
	return {
		"tag_name": PopochiuEditorHelper.EMPTY_STRING,
		"import": PopochiuConfig.is_default_animation_import_enabled(),
		"loops": false,
		"autoplays": false,
		"prop_visible": PopochiuConfig.is_default_animation_prop_visible(),
		"prop_clickable": PopochiuConfig.is_default_animation_prop_clickable(),
	}


func _on_import_toggled(button_pressed:bool) -> void:
	_anim_tag_state.import = button_pressed
	emit_signal("tag_state_changed")


func _on_loops_toggled(button_pressed:bool) -> void:
	_anim_tag_state.loops = button_pressed
	emit_signal("tag_state_changed")


func _on_autoplays_toggled(button_pressed:bool) -> void:
	_anim_tag_state.autoplays = button_pressed
	emit_signal("tag_state_changed")


func _on_visible_toggled(button_pressed:bool) -> void:
	_anim_tag_state.prop_visible = button_pressed
	emit_signal("tag_state_changed")


func _on_clickable_toggled(button_pressed:bool) -> void:
	_anim_tag_state.prop_clickable = button_pressed
	emit_signal("tag_state_changed")


func _on_tag_name_pressed() -> void:
	# Parent will handle the delete request, passing the tag name.
	emit_signal("tag_selected", _anim_tag_state.tag_name)


func _on_delete_anim_pressed() -> void:
	# Parent will handle the delete request, passing the tag name.
	emit_signal("request_delete_anim", _anim_tag_state.tag_name)


#endregion
