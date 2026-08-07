@tool
extends HBoxContainer

# A single row representing a "group tag" in the importer dock tag list.
# It carries the prop-level toggles (Import, Visible, Clickable); the
# animation-level toggles (Loops, Autoplays) live on its child rows.

signal tag_state_changed

var tag_name_label: Control
var import_toggle: Control
var visible_toggle: Control
var clickable_toggle: Control

var _anim_tag_state: Dictionary = {}
var _display_name: String = PopochiuEditorHelper.EMPTY_STRING

#region Public #####################################################################################
func init(group_cfg: Dictionary):
	# Manually initialize node references (the container gets repopulated without
	# the script being reloaded, so @onready is not reliable here).
	tag_name_label = $HBoxContainer/GroupName
	import_toggle = $HBoxContainer/Panel/HBoxContainer/Import
	visible_toggle = $HBoxContainer/Panel/HBoxContainer/Visible
	clickable_toggle = $HBoxContainer/Panel/HBoxContainer/Clickable

	# Set icons manually, like AnimationTagRow does
	import_toggle.icon = get_theme_icon('Load', 'EditorIcons')
	visible_toggle.icon = get_theme_icon('GuiVisibilityVisible', 'EditorIcons')
	clickable_toggle.icon = get_theme_icon('ToolSelect', 'EditorIcons')

	# Bold the group name so it reads as a header over its children
	var bold_font := get_theme_font("bold", "EditorFonts")
	if bold_font:
		tag_name_label.add_theme_font_override("font", bold_font)

	_display_name = group_cfg.get("display_name", group_cfg.get("tag_name", ""))

	_anim_tag_state = {
		"tag_name": "",
		"import": PopochiuConfig.is_default_animation_import_enabled(),
		"prop_visible": PopochiuConfig.is_default_animation_prop_visible(),
		"prop_clickable": PopochiuConfig.is_default_animation_prop_clickable(),
	}
	_anim_tag_state.merge(group_cfg, true)
	_setup_scene()


func get_cfg() -> Dictionary:
	# Only expose the fields that are meaningful to persist; the group structure
	# (children, validation) is always derived from the scan.
	return {
		"tag_name": _anim_tag_state.tag_name,
		"import": _anim_tag_state.import,
		"prop_visible": _anim_tag_state.prop_visible,
		"prop_clickable": _anim_tag_state.prop_clickable,
		"from": _anim_tag_state.get("from", -1),
		"to": _anim_tag_state.get("to", -1),
		"direction": _anim_tag_state.get("direction", "forward"),
	}


func get_search_name() -> String:
	return _display_name if not _display_name.is_empty() else _anim_tag_state.tag_name


# Marks the group as misconfigured: tints the name and adds an explanatory
# tooltip with actionable information.
func set_error(message: String) -> void:
	tag_name_label.add_theme_color_override("font_color", get_theme_color("error_color", "Editor"))
	tag_name_label.tooltip_text = message


#endregion


#region Private ####################################################################################
func _setup_scene() -> void:
	tag_name_label.text = _display_name
	import_toggle.set_pressed_no_signal(_anim_tag_state.import)
	visible_toggle.set_pressed_no_signal(_anim_tag_state.prop_visible)
	clickable_toggle.set_pressed_no_signal(_anim_tag_state.prop_clickable)
	emit_signal("tag_state_changed")


func _on_import_toggled(button_pressed: bool) -> void:
	_anim_tag_state.import = button_pressed
	emit_signal("tag_state_changed")


func _on_visible_toggled(button_pressed: bool) -> void:
	_anim_tag_state.prop_visible = button_pressed
	emit_signal("tag_state_changed")


func _on_clickable_toggled(button_pressed: bool) -> void:
	_anim_tag_state.prop_clickable = button_pressed
	emit_signal("tag_state_changed")


#endregion
