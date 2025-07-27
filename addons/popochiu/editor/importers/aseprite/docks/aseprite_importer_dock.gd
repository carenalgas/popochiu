@tool
extends PanelContainer

# TODO: review coding standards for those constants
const RESULT_CODE = preload("res://addons/popochiu/editor/config/result_codes.gd")
const LOCAL_OBJ_CONFIG = preload("res://addons/popochiu/editor/config/local_obj_config.gd")
# TODO: this can be specialized, even if for a two buttons... ?
const AnimationTagRow =\
preload("res://addons/popochiu/editor/importers/aseprite/docks/animation_tag_row.gd")

enum {
	HANDLE_ANIM_SELECT,
	HANDLE_ANIM_DELETE,
}

enum BulkActionStatus {
	ON,
	OFF,
	DIRTY
}

var target_node: Node
var file_system: EditorFileSystem

# ---- External logic
var _animation_tag_row_scene: PackedScene =\
preload("res://addons/popochiu/editor/importers/aseprite/docks/animation_tag_row.tscn")
var _aseprite = preload("../aseprite_controller.gd").new() ## TODO: should be absolute?
# ---- References for children scripts
var _root_node: Node
var _options: Dictionary
# ---- Importer parameters variables
var _source: String = PopochiuEditorHelper.EMPTY_STRING
var _output_folder := PopochiuEditorHelper.EMPTY_STRING
var _file_dialog_aseprite: FileDialog
var _tags_cache: Array = []
var _importing := false

# A mapping of bulk toggle buttons to their corresponding row properties
var _bulk_toggle_configs = {
	"ImportBulk": {
		"row_property": "import",
		"row_toggle": "import_toggle",
		"default_value": false
	},
	"LoopsBulk": {
		"row_property": "loops",
		"row_toggle": "loops_toggle",
		"default_value": false
	},
	"AutoplaysBulk": {
		"row_property": "autoplays",
		"row_toggle": "autoplays_toggle",
		"default_value": false
	},
	"VisibleBulk": {
		"row_property": "prop_visible",
		"row_toggle": "visible_toggle",
		"default_value": false
	},
	"ClickableBulk": {
		"row_property": "prop_clickable",
		"row_toggle": "clickable_toggle",
		"default_value": false
	}
}

#region Public ######################################################################################
func init():
	# Connect signals

	# Connect to theme changes to update styles if the user
	# sets a different theme for the editor.
	if not theme_changed.is_connected(_on_theme_changed):
		theme_changed.connect(_on_theme_changed)

	# Update default values if the project settings change
	if not ProjectSettings.settings_changed.is_connected(_on_project_settings_changed):
		ProjectSettings.settings_changed.connect(_on_project_settings_changed)

	# Apply filter if the user type into the filter field
	if not %FilterField.text_changed.is_connected(_on_filter_text_changed):
		%FilterField.text_changed.connect(_on_filter_text_changed)

	# Connect each visible bulk toggle button to the generic handler
	# which will perform common behaviors
	for bulk_toggle_name in _bulk_toggle_configs.keys():
		var bulk_toggle = get_node_or_null("%" + bulk_toggle_name)
		if not bulk_toggle or not bulk_toggle.visible:
			continue
		
		# Disconnect all existing connections to the "toggled" signal to prevent duplicates
		for connection in bulk_toggle.get_signal_connection_list("toggled"):
			bulk_toggle.toggled.disconnect(connection.callable)
		
		# Use a lambda to capture the bulk toggle name for the handler
		bulk_toggle.toggled.connect(
			func(pressed): _on_bulk_toggle_toggled(bulk_toggle_name, pressed)
		)

	# Other initialization stuff

	# Update default values for bulk toggles
	_update_default_toggle_values()
	
	# Initialize styles and UI elements visibility
	_set_elements_styles()
	_customize_filter_ui()

	_set_tags_visible(false)

	# Check access to Aseprite executable
	var result := _check_aseprite()
	if result == RESULT_CODE.SUCCESS:
		_show_importer()
	else:
		PopochiuUtils.print_error(RESULT_CODE.get_error_message(result))
		_show_warning()

	# Load inspector dock configuration from node
	# or from the game resources, if the node is null.
	var cfg := LOCAL_OBJ_CONFIG.load_config(target_node)
	if cfg.is_empty():
		_load_default_config()
	else:
		_load_config(cfg)
		_set_tags_visible(cfg.get("tags_exp"))


#endregion


#region Protected ##################################################################################
# Returns the default loop behavior for animations based on the object type.
# This method should be overridden by child classes to provide type-specific defaults.
func _get_default_loop_behavior() -> bool:
	# Base implementation returns false (no looping by default)
	return false

# Returns the default autoplay behavior for animations based on the object type.
# This method should be overridden by child classes to provide type-specific defaults.
func _get_default_autoplay_behavior() -> bool:
	# Base implementation returns false (no autoplay by default)
	return false


# This method can be overridden by child classes to customize the tag UI,
# such as enabling additional buttons or similar.
func _customize_tag_ui(tagrow: AnimationTagRow) -> void:
	## This can be implemented by child classes if necessary
	pass

# This method can be overridden by child classes to customize the filter bar UI,
# such as enabling additional buttons or similar.
func _customize_filter_ui() -> void:
	## This can be implemented by child classes if necessary
	pass

# Selects an animation in the AnimationPlayer of a target node.
# Should be overridden by child classes to provide type-specific behavior.
func _select_animation(tag_name: String) -> void:
	# Base implementation, to be overridden by child classes
	pass

# Deletes an animation from the AnimationPlayer of a target node.
# Should be overridden by child classes to provide type-specific behavior.
func _delete_animation_for_tag(tag_name: String) -> void:
	# Base implementation, to be overridden by child classes
	pass


#endregion


#region Signals Handlers ####################################################################################
# Filters the tag list based on the search text in the FilterField.
# Tags whose names contain the search string (case-insensitive, ignoring spaces) will be shown.
func _on_filter_text_changed(new_text: String) -> void:
	var filter_text := new_text.strip_edges().to_lower().replace(" ", "")
	
	for tag_row in %Tags.get_children():
		if filter_text.is_empty():
			# Show all tags when filter is empty
			tag_row.visible = true
		else:
			# Compare with tag name (removing spaces, case insensitive)
			var tag_name: String = tag_row.get_cfg().tag_name.to_lower().replace(" ", "")
			tag_row.visible = tag_name.contains(filter_text)


func _on_source_pressed() -> void:
	_open_source_dialog()


func _on_aseprite_file_selected(path) -> void:
	_set_source(ProjectSettings.localize_path(path))
	_scan_source()
	_file_dialog_aseprite.queue_free()


func _on_rescan_pressed() -> void:
	_scan_source()


func _on_import_pressed() -> void:
	if _importing:
		return
	
	_importing = true
	_root_node = get_tree().get_edited_scene_root()

	_output_folder = (
		PopochiuResources.INVENTORY_ITEMS_PATH if _root_node == null
		else _root_node.scene_file_path.get_base_dir()
	)
	
	if _source == PopochiuEditorHelper.EMPTY_STRING:
		_show_message("Aseprite file not selected")
		_importing = false
		return
	
	_options = {
		"source": ProjectSettings.globalize_path(_source),
		"tags": _tags_cache,
		"output_folder": _output_folder,
		"only_visible_layers": %VisibleLayersCheckButton.is_pressed(),
		"wipe_old_animations": %WipeOldAnimationsCheckButton.is_pressed(),
	}

	_save_config()


func _on_reset_pressed() -> void:
	var confirmation_dialog = _show_confirmation(\
		"This will reset the importer preferences. " + \
		"This cannot be undone! Are you sure?", "Confirmation required!")
	confirmation_dialog.get_ok_button().pressed.connect(_reset_prefs_metadata)


func _on_request_delete_anim(tag_name: String) -> void:
	var delete_dialog = PopochiuEditorHelper.DELETE_CONFIRMATION_SCENE.instantiate()
	
	delete_dialog.title = "Remove animation for tag %s?" % tag_name
	delete_dialog.message = "This will [b]NOT[/b] remove [b]%s[/b] prop or inventory item, but only the %s animation!" % [tag_name, tag_name.to_snake_case()]
	delete_dialog.ask = "Remove the animation for tag [b]%s[/b]?" % tag_name
	delete_dialog.on_confirmed = _delete_animation_for_tag.bind(tag_name)
	
	PopochiuEditorHelper.show_delete_confirmation(delete_dialog)


# Called when project settings that affect default values have changed.
func _on_project_settings_changed() -> void:
	_update_default_toggle_values()
	
	# Only update UI if it's already populated
	if %Tags.get_child_count() > 0:
		_update_all_bulk_toggles_state()


# Called when the editor theme changes to update UI styling.
func _on_theme_changed() -> void:
	# Defer the style update to ensure theme cache is fully updated.
	call_deferred("_set_elements_styles")


# Generic handler for any bulk toggle button press.
# Determines the action based on whether the toggle is in a clean or "dirty" state.
func _on_bulk_toggle_toggled(bulk_toggle_name: String, button_pressed: bool) -> void:
	var bulk_toggle = get_node("%" + bulk_toggle_name)
	
	# If all tags are in a consistent state, simply toggle them all
	if not bulk_toggle.has_meta("is_dirty") or not bulk_toggle.get_meta("is_dirty"):
		_set_all_row_toggle_states(bulk_toggle_name, button_pressed)
		return
	
	# If in a mixed state ("dirty"), show confirmation dialog
	var confirmation_dialog = _show_confirmation(
		"This will reset all " + bulk_toggle_name.replace("Bulk", "").to_lower() + " toggles to their default state.\n" +
		"Your individual tag preferences will be lost. Are you sure?",
		"Confirmation required!"
	)
	
	confirmation_dialog.get_ok_button().pressed.connect(
		_reset_toggle_preferences.bind(bulk_toggle_name)
	)
	
	# Reset the toggle to off state since we need confirmation
	bulk_toggle.set_pressed_no_signal(false)


func _on_tag_selected(tag_name: String) -> void:
	# Call the strategy-specific implementation
	_select_animation(tag_name)


#endregion


#region Private ####################################################################################
func _check_aseprite() -> int:
	if not _aseprite.check_command_path():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FULL_PATH
	
	if not _aseprite.test_command():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FOUND
	
	return RESULT_CODE.SUCCESS	


func _list_tags(file: String):
	if not _aseprite.check_command_path():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FULL_PATH
	if not _aseprite.test_command():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FOUND
	return _aseprite.list_tags(file)


# TODO: Currently unused. keeping this as reference
# to populate a checkable list of layers
func _list_layers(file: String, only_visibles = false):
	if not _aseprite.check_command_path():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FULL_PATH
	if not _aseprite.test_command():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FOUND
	return _aseprite.list_layers(file, only_visibles)


func _load_config(cfg) -> void:
	if cfg.has("source"):
		_set_source(cfg.source)

	%VisibleLayersCheckButton.set_pressed_no_signal(
		cfg.get("only_visible_layers", false)
	)
	%WipeOldAnimationsCheckButton.set_pressed_no_signal(
		cfg.get("wipe_old_anims", false)
	)

	_set_tags_visible(cfg.get("tags_exp", false))
	_populate_tags(cfg.get("tags", []))


func _save_config() -> void:
	_update_tags_cache()

	var cfg := {
		"source": _source,
		"tags": _tags_cache,
		"tags_exp": %Tags.visible,
		"only_visible_layers": %VisibleLayersCheckButton.is_pressed(),
		"wipe_old_anims": %WipeOldAnimationsCheckButton.is_pressed(),
	}

	LOCAL_OBJ_CONFIG.save_config(target_node, cfg)

	# Update bulk toggles to reflect the collective state of individual tags
	_update_all_bulk_toggles_state()


func _load_default_config() -> void:
	# Reset variables
	_source = PopochiuEditorHelper.EMPTY_STRING
	_tags_cache = []
	_output_folder = PopochiuEditorHelper.EMPTY_STRING

	# Empty tags list
	_empty_tags_container()

	# Reset inspector fields
	%SourceButton.text = "[empty]"
	%SourceButton.tooltip_text = PopochiuEditorHelper.EMPTY_STRING
	%VisibleLayersCheckButton.set_pressed_no_signal(
		PopochiuConfig.is_default_only_visible_layers()
	)
	%WipeOldAnimationsCheckButton.set_pressed_no_signal(
		PopochiuConfig.is_default_wipe_old_anims_enabled()
	)


func _set_source(source) -> void:
	_source = source
	%SourceButton.text = _source
	%SourceButton.tooltip_text = _source


func _reset_prefs_metadata() -> void:
	LOCAL_OBJ_CONFIG.remove_config(target_node)
	_load_default_config()
	notify_property_list_changed()
	_set_tags_visible(false)


func _open_source_dialog() -> void:
	_file_dialog_aseprite = _create_aseprite_file_selection()
	get_parent().add_child(_file_dialog_aseprite)
	if _source != PopochiuEditorHelper.EMPTY_STRING:
		_file_dialog_aseprite.set_current_dir(
			ProjectSettings.globalize_path(
				_source.get_base_dir()
			)
		)
	_file_dialog_aseprite.popup_centered_ratio()


func _create_aseprite_file_selection() -> FileDialog:
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.title = "Select Aseprite animation file"
	file_dialog.file_selected.connect(_on_aseprite_file_selected)
	file_dialog.set_filters(PackedStringArray(["*.ase","*.aseprite"]))
	return file_dialog


func _scan_source() -> void:
	_populate_tags(
		_merge_with_cache(_get_tags_from_source())
	)
	_save_config()
	_set_tags_visible(true)


func _populate_tags(tags: Array) -> void:
	## reset tags container
	_empty_tags_container()

	# Add each tag found
	for t in tags:
		if t.tag_name == PopochiuEditorHelper.EMPTY_STRING:
			continue
		
		var tag_row: AnimationTagRow = _animation_tag_row_scene.instantiate()
		%Tags.add_child(tag_row)
		tag_row.init(t)
		tag_row.tag_state_changed.connect(_save_config)
		tag_row.tag_selected.connect(_on_tag_selected)
		tag_row.request_delete_anim.connect(_on_request_delete_anim)
		_customize_tag_ui(tag_row)
		# Invoke customization hook implementable in child classes		
	
	_update_tags_cache()
	_update_bulk_toggles_state() # Update bulk toggles after populating tags


func _empty_tags_container() -> void:
	# Clean the inspector tags container empty
	for tl in %Tags.get_children():
		%Tags.remove_child(tl)
		tl.queue_free()


func _update_tags_cache() -> void:
	_tags_cache = _get_tags_from_ui()


func _merge_with_cache(tags: Array) -> Array:
	var tags_cache_index = {}
	var result = []
	for t in _tags_cache:
		tags_cache_index[t.tag_name] = t
	
	for i in tags.size():
		if tags_cache_index.has(tags[i].tag_name):
			# Use cached version (preserves user settings)
			result.push_back(tags_cache_index[tags[i].tag_name])
		else:
			# New tag: set default loop and autoplay behavior based on object type
			tags[i].loops = _get_default_loop_behavior()
			tags[i].autoplays = _get_default_autoplay_behavior()
			result.push_back(tags[i])

	return result


func _get_tags_from_ui() -> Array:
	var tags_list = []
	for tag_row in %Tags.get_children():
		var tag_row_cfg: Dictionary = tag_row.get_cfg()
		if tag_row_cfg.tag_name == PopochiuEditorHelper.EMPTY_STRING:
			continue
		tags_list.push_back(tag_row_cfg)
	return tags_list


func _get_tags_from_source() -> Array:
	var tags_found = _list_tags(ProjectSettings.globalize_path(_source))
	if typeof(tags_found) == TYPE_INT:
		PopochiuUtils.print_error(RESULT_CODE.get_error_message(tags_found))
		return []
	var tags_list = []
	for t in tags_found:
		if t == PopochiuEditorHelper.EMPTY_STRING:
			continue
		tags_list.push_back({
			tag_name = t
		})
	return tags_list


func _show_message(
	message: String, title: String = PopochiuEditorHelper.EMPTY_STRING, object: Object = null, method := PopochiuEditorHelper.EMPTY_STRING
) -> void:
	var warning_dialog = AcceptDialog.new()
	
	if title != PopochiuEditorHelper.EMPTY_STRING:
		warning_dialog.title = title
	
	warning_dialog.dialog_text = message
	warning_dialog.popup_window = true
	
	var callback := Callable(warning_dialog, "queue_free")
	
	if is_instance_valid(object) and not method.is_empty():
		callback = func():
			object.call(method)
	
	warning_dialog.confirmed.connect(callback)
	warning_dialog.close_requested.connect(callback)
	
	PopochiuEditorHelper.show_dialog(warning_dialog)


func _show_confirmation(message: String, title: String = PopochiuEditorHelper.EMPTY_STRING) -> ConfirmationDialog:
	var _confirmation_dialog = ConfirmationDialog.new()
	get_parent().add_child(_confirmation_dialog)
	if title != PopochiuEditorHelper.EMPTY_STRING:
		_confirmation_dialog.title = title
	_confirmation_dialog.dialog_text = message
	_confirmation_dialog.popup_centered()
	_confirmation_dialog.close_requested.connect(_confirmation_dialog.queue_free)
	return _confirmation_dialog


func _set_tags_visible(is_visible: bool) -> void:
	# If the tags container is empty, we show an info box
	%TagsInfo.visible = %Tags.get_child_count() == 0
	%FilterBulkBtnContainer.visible = is_visible && %Tags.get_child_count() > 0
	%TagsScrollContainer.visible = is_visible


func _set_elements_styles() -> void:
	# Use the editor's section stylebox and remove borders to maintain theme consistency
	var section_style = get_theme_stylebox("normal", "Button").duplicate()
	section_style.set_border_width_all(0)
	section_style.set_content_margin_all(0)

	%FilterBulkBtnContainer.add_theme_stylebox_override("panel", section_style)
	%OptionsContainer.add_theme_stylebox_override("panel", section_style)

	# Set style of warning panel
	%WarningLabel.add_theme_color_override("font_color", get_theme_color("error_color", "Editor"))

	# Style the title buttons with proper theme colors
	var normal_color = get_theme_color("font_color", "Label")
	var hover_color = get_theme_color("font_hover_color", "Button")
	var pressed_color = get_theme_color("font_pressed_color", "Button")

	%Import.set_button_icon(get_theme_icon("MoveDown", "EditorIcons"))
	%Reset.set_button_icon(get_theme_icon("Clear", "EditorIcons"))

	# Set filter bar icons
	%ImportBulk.set_button_icon(get_theme_icon('Load', 'EditorIcons'))
	%LoopsBulk.set_button_icon(get_theme_icon('Loop', 'EditorIcons'))
	%AutoplaysBulk.set_button_icon(get_theme_icon('AutoPlay', 'EditorIcons'))
	# 2. Room-related toggles icons
	%VisibleBulk.set_button_icon(get_theme_icon('GuiVisibilityVisible', 'EditorIcons'))
	%ClickableBulk.set_button_icon(get_theme_icon('ToolSelect', 'EditorIcons'))

func _show_warning() -> void:
	%Warning.visible = true
	%Importer.visible = false
	

func _show_importer() -> void:
	%Warning.visible = false
	%Importer.visible = true


func _handle_animation_in_player(tag_name: String, animation_player: AnimationPlayer, action: int = HANDLE_ANIM_SELECT) -> void:
	if tag_name.is_empty():
		PopochiuUtils.print_warning("No tag name provided for selection.")
		return

	if not is_instance_valid(animation_player):
		PopochiuUtils.print_warning("No AnimationPlayer found in character node.")
		return

	# Select the AnimationPlayer node in the editor
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(animation_player)

	# Find the animation by tag name (converting to snake_case as that's how animations are named)
	var animation_name = tag_name.to_snake_case()
	if animation_player.has_animation(animation_name):
		match action:
			HANDLE_ANIM_SELECT:
				# Set the animation as the current one in the AnimationPlayer
				animation_player.assigned_animation = animation_name
			HANDLE_ANIM_DELETE:
				# If the action is to delete, we first need to find which library contains this animation
				var library_name = animation_player.find_animation_library(
					animation_player.get_animation(animation_name)
				)
				# Get the library and remove the animation from it
				var library = animation_player.get_animation_library(library_name)
				if library:
					library.remove_animation(animation_name)
			_:
				PopochiuUtils.print_warning("Unknown action for animation handling: %s." % action)
	else:
		PopochiuUtils.print_warning("No animation named '%s' found in character's AnimationPlayer." % animation_name)


# Called after populating tags or when their state changes.
# Updates the state of bulk action buttons based on individual tag states.
func _update_bulk_toggles_state() -> void:
	# Handle ImportBulk toggle state
	if %Tags.get_child_count() == 0:
		return
		
	var all_import := true
	var none_import := true
	
	# Check all tags to determine the collective state
	for tag_row in %Tags.get_children():
		var cfg: Dictionary = tag_row.get_cfg()
		if cfg.import:
			none_import = false
		else:
			all_import = false
	
	# Set the toggle state based on the collective state
	if all_import:
		# All tags are set to import
		%ImportBulk.set_pressed_no_signal(true)
		%ImportBulk.set_meta("is_dirty", false)
		%ImportBulk.remove_theme_color_override("icon_normal_color")
	elif none_import:
		# No tags are set to import
		%ImportBulk.set_pressed_no_signal(false)
		%ImportBulk.set_meta("is_dirty", false)
		%ImportBulk.remove_theme_color_override("icon_normal_color")
	else:
		# Mixed state - mark as "dirty"
		%ImportBulk.set_pressed_no_signal(false)
		%ImportBulk.set_meta("is_dirty", true)
		%ImportBulk.add_theme_color_override(
			"icon_normal_color",
			get_theme_color("disabled_font_color", "Editor")
		)


# Updates the state of all visible bulk toggle buttons based on individual tag states.
func _update_all_bulk_toggles_state() -> void:	
	if %Tags.get_child_count() == 0:
		return
		
	# Update each bulk toggle that's visible in the UI
	for bulk_toggle_name in _bulk_toggle_configs.keys():
		if get_node_or_null("%" + bulk_toggle_name):
			_update_bulk_toggle_state(bulk_toggle_name)


# Sets the visual state and metadata for a bulk toggle button.
func _set_bulk_toggle_visual_state(bulk_toggle_name: String, status: BulkActionStatus) -> void:
	var bulk_toggle = get_node("%" + bulk_toggle_name)
	if not bulk_toggle:
		return
	
	match status:
		BulkActionStatus.ON:
			bulk_toggle.set_pressed_no_signal(true)
			bulk_toggle.set_meta("is_dirty", false)
			bulk_toggle.remove_theme_color_override("icon_normal_color")
		BulkActionStatus.OFF:
			bulk_toggle.set_pressed_no_signal(false)
			bulk_toggle.set_meta("is_dirty", false)
			bulk_toggle.remove_theme_color_override("icon_normal_color")
		BulkActionStatus.DIRTY:
			bulk_toggle.set_pressed_no_signal(false)
			bulk_toggle.set_meta("is_dirty", true)
			bulk_toggle.add_theme_color_override(
				"icon_normal_color",
				get_theme_color("disabled_font_color", "Editor")
			)


# Updates a specific bulk toggle button's state based on individual tag states.
func _update_bulk_toggle_state(bulk_toggle_name: String) -> void:
	var bulk_toggle = get_node("%" + bulk_toggle_name)
	if not bulk_toggle:
		return

	var config = _bulk_toggle_configs[bulk_toggle_name]
	var status: BulkActionStatus
	var first_iteration := true

	# Check all visible tag rows to determine the collective state
	for tag_row in %Tags.get_children():
		var cfg: Dictionary = tag_row.get_cfg()
		var current_row_status = BulkActionStatus.ON if cfg.get(config.row_property) else BulkActionStatus.OFF

		if first_iteration:
			# Set initial status from first row
			status = current_row_status
			first_iteration = false
		elif status != current_row_status:
			# Mixed state detected, exit early
			status = BulkActionStatus.DIRTY
			break

	# Set the toggle state based on the determined status
	_set_bulk_toggle_visual_state(bulk_toggle_name, status)


# Sets all tag rows' toggle state for a specific property.
func _set_all_row_toggle_states(bulk_toggle_name: String, toggle_state: bool) -> void:
	var config = _bulk_toggle_configs[bulk_toggle_name]
	
	for tag_row in %Tags.get_children():
		var toggle = tag_row.get(config.row_toggle)
		if toggle:
			toggle.set_pressed_no_signal(toggle_state)
	
			# Update the underlying data
			var cfg: Dictionary = tag_row.get_cfg()
			cfg[config.row_property] = toggle_state
	
	# Update the bulk toggle to reflect the new state
	var status = BulkActionStatus.ON if toggle_state else BulkActionStatus.OFF
	_set_bulk_toggle_visual_state(bulk_toggle_name, status)

	_save_config()


# Resets toggle preferences for a specific property to default values.
func _reset_toggle_preferences(bulk_toggle_name: String) -> void:
	var config = _bulk_toggle_configs[bulk_toggle_name]
	var default_value: bool = config.get("default_value", false)
		
	_set_all_row_toggle_states(bulk_toggle_name, default_value)


# Updates the default values for all bulk toggles from their respective sources.
func _update_default_toggle_values() -> void:
	# assign local values
	_bulk_toggle_configs["LoopsBulk"]["default_value"] = _get_default_loop_behavior()
	_bulk_toggle_configs["AutoplaysBulk"]["default_value"] = _get_default_autoplay_behavior()
	
	# Assign general configuration defaults
	_bulk_toggle_configs["ImportBulk"]["default_value"] = PopochiuConfig.is_default_animation_import_enabled()
	_bulk_toggle_configs["VisibleBulk"]["default_value"] = PopochiuConfig.is_default_animation_prop_visible()
	_bulk_toggle_configs["ClickableBulk"]["default_value"] = PopochiuConfig.is_default_animation_prop_clickable()
