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

# When the row is a child of a group, _display_name holds the animation name
# (group prefix stripped) and _group_name the group it belongs to.
var _display_name: String = PopochiuEditorHelper.EMPTY_STRING
var _group_name: String = PopochiuEditorHelper.EMPTY_STRING

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
	
	# The action buttons live in a right-anchored grid. Only leading columns
	# (Visible/Clickable) are ever hidden on this row, so the remaining buttons
	# keep their right-anchored columns and stay aligned with every other row
	# type. Default state (characters): only Import and Loops.
	_setup_action_grid()
	visible_toggle.visible = false
	clickable_toggle.visible = false
	autoplays_toggle.visible = false
	separator.visible = false
	import_toggle.visible = true
	loops_toggle.visible = true
	
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
	visible_toggle.visible = true
	clickable_toggle.visible = true
	autoplays_toggle.visible = true
	separator.visible = true
	import_toggle.visible = true
	loops_toggle.visible = true

func show_inventory_item_buttons() -> void:
	visible_toggle.visible = false
	clickable_toggle.visible = false
	autoplays_toggle.visible = true
	separator.visible = true
	import_toggle.visible = true
	loops_toggle.visible = true


# Makes the row behave as a child of a group: it only owns the animation-level
# toggles (Loops/Autoplays); the prop-level ones (Visible/Clickable) live on the
# group header row. The displayed name is the animation name.
func set_group_child(group_name: String) -> void:
	_group_name = group_name
	visible_toggle.visible = false
	clickable_toggle.visible = false
	autoplays_toggle.visible = true
	separator.visible = true
	import_toggle.visible = true
	loops_toggle.visible = true


# Changes the displayed name (used for group children, whose label is the
# animation name with the group prefix stripped).
func set_display_name(name: String) -> void:
	_display_name = name
	tag_name_label.text = name


# The name used by the tag list filter: prefers the displayed (stripped) name.
func get_search_name() -> String:
	return _display_name if not _display_name.is_empty() else _anim_tag_state.tag_name


# The group this row belongs to, or an empty string for standalone tags.
func get_group_name() -> String:
	return _group_name


# Updates the autoplay state without emitting signals. Used to enforce autoplay
# exclusivity within a group (only one child can autoplay).
func set_autoplay_no_signal(pressed: bool) -> void:
	_anim_tag_state.autoplays = pressed
	autoplays_toggle.set_pressed_no_signal(pressed)


#endregion

#region SetGet #####################################################################################
func get_cfg() -> Dictionary:
	return _anim_tag_state


#endregion

#region Private ####################################################################################
# Gives every action button a fixed width. The buttons live in a container that
# is anchored to the row's right edge and sized to its visible children, so the
# same action always occupies the same column in every row type, even when
# leading buttons (Visible/Clickable) are hidden.
func _setup_action_grid() -> void:
	# Trim the flat-button padding so every action button is exactly 20px wide
	# (the tag row's grid is made only of buttons, so it is always consistent).
	for control in [visible_toggle, clickable_toggle, autoplays_toggle, import_toggle, loops_toggle]:
		PopochiuEditorHelper.make_icon_button_slot(control)
	separator.custom_minimum_size = Vector2(1, 0)
	# Size the grid to its visible children and keep it anchored to the right.
	$HBoxContainer/Panel/HBoxContainer.offset_left = 0.0


func _setup_scene() -> void:
	tag_name_label.text = _anim_tag_state.tag_name
	import_toggle.set_pressed_no_signal(_anim_tag_state.import)
	loops_toggle.set_pressed_no_signal(_anim_tag_state.loops)
	autoplays_toggle.set_pressed_no_signal(_anim_tag_state.autoplays)
	visible_toggle.set_pressed_no_signal(_anim_tag_state.prop_visible)
	clickable_toggle.set_pressed_no_signal(_anim_tag_state.prop_clickable)
	_update_frame_tooltip()
	emit_signal("tag_state_changed")


# Shows the frame info as a tooltip on the tag name, e.g. "4 frames [12-15]".
# Aseprite's JSON indices are 0-based, so the range is shown 1-based to match
# the Aseprite editor UI.
func _update_frame_tooltip() -> void:
	var tag_from = _anim_tag_state.get("from", -1)
	var tag_to = _anim_tag_state.get("to", -1)
	if (
		typeof(tag_from) in [TYPE_INT, TYPE_FLOAT]
		and typeof(tag_to) in [TYPE_INT, TYPE_FLOAT]
		and int(tag_from) >= 0
		and int(tag_to) >= int(tag_from)
	):
		tag_name_label.tooltip_text = _frame_info_text(int(tag_from), int(tag_to))
	else:
		tag_name_label.tooltip_text = ""


func _frame_info_text(tag_from: int, tag_to: int) -> String:
	var count := tag_to - tag_from + 1
	if count == 1:
		return "1 frame [%d]" % (tag_from + 1)
	return "%d frames [%d-%d]" % [count, tag_from + 1, tag_to + 1]


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
