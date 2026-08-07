@tool
extends PanelContainer

# TODO: review coding standards for those constants
const RESULT_CODE = preload("res://addons/popochiu/editor/config/result_codes.gd")
const LOCAL_OBJ_CONFIG = preload("res://addons/popochiu/editor/config/local_obj_config.gd")
# TODO: this can be specialized, even if for a two buttons... ?
const AnimationTagRow =\
preload("res://addons/popochiu/editor/importers/aseprite/docks/animation_tag_row.gd")
const AnimationGroupRow =\
preload("res://addons/popochiu/editor/importers/aseprite/docks/animation_group_row.gd")
const PopochiuAsepriteTagGrouper =\
preload("res://addons/popochiu/editor/importers/aseprite/aseprite_tag_grouper.gd")

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
var _animation_group_row_scene: PackedScene =\
preload("res://addons/popochiu/editor/importers/aseprite/docks/animation_group_row.tscn")
var _aseprite := preload("../aseprite_controller.gd").new() # TODO: should be absolute?
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
func init() -> void:
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


# Returns whether this importer supports "group tags" (one object with several
# animations). Only the room importer supports groups for now.
func _supports_groups() -> bool:
	return false


# This method can be overridden by child classes to customize the tag UI,
# such as enabling additional buttons or similar.
func _customize_tag_ui(tagrow: AnimationTagRow) -> void:
	# This can be implemented by child classes if necessary.
	pass

# This method can be overridden by child classes to customize the filter bar UI,
# such as enabling additional buttons or similar.
func _customize_filter_ui() -> void:
	# This can be implemented by child classes if necessary.
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
	
	for tag_row in _get_all_tag_rows():
		if filter_text.is_empty():
			# Show all tags when filter is empty
			tag_row.visible = true
		else:
			# Compare with the (displayed) name, removing spaces, case insensitive
			var tag_name: String = tag_row.get_search_name().to_lower().replace(" ", "")
			tag_row.visible = tag_name.contains(filter_text)


# Handles tag row state changes that need coordination between rows.
# Autoplay is exclusive within a group: enabling it on a child disables it on
# all the other children of the same group.
func _on_tag_state_changed(tag_row: AnimationTagRow) -> void:
	var group_name: String = tag_row.get_group_name()
	if group_name.is_empty():
		return

	if not tag_row.get_cfg().get("autoplays", false):
		return

	var changed := false
	for row in _get_all_tag_rows():
		if (
			row is AnimationTagRow
			and row != tag_row
			and row.get_group_name() == group_name
			and row.get_cfg().get("autoplays", false)
		):
			row.set_autoplay_no_signal(false)
			changed = true

	if changed:
		_save_config()


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
	var anim_name := tag_name.to_snake_case()
	delete_dialog.message = (
		"This will [b]NOT[/b] remove [b]%s[/b] prop or inventory item, but only the %s animation!"
		% [tag_name, anim_name]
	)
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


func _list_tags(file: String) -> Variant:
	if not _aseprite.check_command_path():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FULL_PATH
	if not _aseprite.test_command():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FOUND
	return _aseprite.list_tags(file)


# Slow variant used only at import time: fetches the tag frame ranges needed to
# export group spritesheets. The dock scan only needs names (see _list_tags).
func _list_tags_with_ranges(file: String) -> Variant:
	if not _aseprite.check_command_path():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FULL_PATH
	if not _aseprite.test_command():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FOUND
	return _aseprite.list_tags_with_ranges(file)


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
	%AutotracePolygonsCheckButton.set_pressed_no_signal(
		cfg.get("autotrace_polygons", false)
	)

	# Restore the tag list. When groups are supported, refresh the persisted
	# frame data against the current source file: ranges stored in the metadata
	# can be outdated (e.g. if the room was last saved before a re-scan), which
	# would otherwise break group detection on reload. Falls back to the saved
	# list when the source can't be read.
	var saved_tags: Array = cfg.get("tags", [])
	if _supports_groups() and not _source.is_empty():
		_tags_cache = saved_tags
		var refreshed: Array = _merge_with_cache(_get_tags_from_source())
		if _has_group_tags(refreshed):
			refreshed = _merge_with_cache(_get_tags_from_source_with_ranges())
		if not refreshed.is_empty():
			saved_tags = refreshed

	_set_tags_visible(cfg.get("tags_exp", false))
	_populate_tags(saved_tags)


func _save_config() -> void:
	_update_tags_cache()

	var cfg := {
		"source": _source,
		"tags": _tags_cache,
		"tags_exp": %Tags.visible,
		"only_visible_layers": %VisibleLayersCheckButton.is_pressed(),
		"wipe_old_anims": %WipeOldAnimationsCheckButton.is_pressed(),
		"autotrace_polygons": %AutotracePolygonsCheckButton.is_pressed(),
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
	%AutotracePolygonsCheckButton.set_pressed_no_signal(
		PopochiuConfig.is_default_autotrace_polygons()
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
	var tags: Array = _merge_with_cache(_get_tags_from_source())
	# Group tags carry frame ranges used for validation and the safety net.
	# Fetch them at scan time (data-only, fast) so problems are actionable
	# before importing, not after.
	if _supports_groups() and _has_group_tags(tags):
		tags = _merge_with_cache(_get_tags_from_source_with_ranges())
	_populate_tags(tags)
	_save_config()
	_set_tags_visible(true)


# Whether any of the tags is a "group tag" (@ prefix). Frame ranges are only
# worth fetching at scan time when at least one group tag exists.
func _has_group_tags(tags: Array) -> bool:
	for tag in tags:
		if str(tag.get("tag_name", "")).begins_with(PopochiuAsepriteTagGrouper.GROUP_PREFIX):
			return true
	return false


func _populate_tags(tags: Array) -> void:
	# Reset tags container.
	_empty_tags_container()

	if not _supports_groups():
		_populate_flat_tags(tags)
		_update_tags_cache()
		_update_bulk_toggles_state() # Update bulk toggles after populating tags
		return

	var grouper := PopochiuAsepriteTagGrouper.new()
	var analysis := grouper.analyze(tags)

	# Surface configuration problems as soon as the list is built (scan or
	# reload), so the user can fix the Aseprite file before importing.
	for importer_error in analysis.get("errors", []):
		PopochiuUtils.print_error(importer_error)
	for importer_warning in analysis.get("warnings", []):
		PopochiuUtils.print_warning(importer_warning)

	# Render groups and standalone tags in their source order
	for item in analysis.get("items", []):
		if item.get("kind") == "group":
			_add_group_rows(item, tags)
		else:
			var tag: Dictionary = item.get("tag", {})
			if tag.get("tag_name", PopochiuEditorHelper.EMPTY_STRING) == PopochiuEditorHelper.EMPTY_STRING:
				continue
			_add_single_tag_row(tag)

	_update_tags_cache()
	_update_bulk_toggles_state() # Update bulk toggles after populating tags


# Populates the tag list without group handling (used by importers that don't
# support groups, e.g. characters and inventory items).
func _populate_flat_tags(tags: Array) -> void:
	for t in tags:
		if t.tag_name == PopochiuEditorHelper.EMPTY_STRING:
			continue
		var tag_row: AnimationTagRow = _animation_tag_row_scene.instantiate()
		%Tags.add_child(tag_row)
		tag_row.init(t)
		_connect_tag_row_signals(tag_row)
		_customize_tag_ui(tag_row)


# Adds a group header row and its child rows (indented) to the tag list.
func _add_group_rows(group: Dictionary, tags: Array) -> void:
	var group_cfg := _find_tag_cfg(tags, group.get("tag_name", ""))
	var group_row_cfg := group.duplicate()
	group_row_cfg.merge({
		"tag_name": group.get("tag_name", ""),
		"display_name": group.get("name", ""),
		"from": group.get("from", -1),
		"to": group.get("to", -1),
		"direction": group.get("direction", "forward"),
		"import": group_cfg.get("import", PopochiuConfig.is_default_animation_import_enabled()),
		"prop_visible": group_cfg.get("prop_visible", PopochiuConfig.is_default_animation_prop_visible()),
		"prop_clickable": group_cfg.get("prop_clickable", PopochiuConfig.is_default_animation_prop_clickable()),
	})

	var group_row: AnimationGroupRow = _animation_group_row_scene.instantiate()
	%Tags.add_child(group_row)
	group_row.init(group_row_cfg)
	group_row.tag_state_changed.connect(_save_config)

	if not group.get("is_valid", true):
		group_row.set_error(group.get("error", ""))

	# Child rows are indented under the group header
	var indent := MarginContainer.new()
	indent.add_theme_constant_override("margin_left", 18)
	var children_container := VBoxContainer.new()
	indent.add_child(children_container)
	%Tags.add_child(indent)

	for child in group.get("children", []):
		var child_cfg := _find_tag_cfg(tags, child.tag_name)
		if child_cfg.is_empty():
			continue
		var tag_row: AnimationTagRow = _animation_tag_row_scene.instantiate()
		children_container.add_child(tag_row)
		tag_row.init(child_cfg)
		tag_row.set_display_name(child.anim_name)
		tag_row.set_group_child(group.get("name", ""))
		_connect_tag_row_signals(tag_row)


func _add_single_tag_row(tag_cfg: Dictionary) -> void:
	var tag_row: AnimationTagRow = _animation_tag_row_scene.instantiate()
	%Tags.add_child(tag_row)
	tag_row.init(tag_cfg)
	_connect_tag_row_signals(tag_row)
	_customize_tag_ui(tag_row)


func _connect_tag_row_signals(tag_row: AnimationTagRow) -> void:
	tag_row.tag_state_changed.connect(_save_config)
	tag_row.tag_state_changed.connect(_on_tag_state_changed.bind(tag_row))
	tag_row.tag_selected.connect(_on_tag_selected)
	tag_row.request_delete_anim.connect(_on_request_delete_anim)


func _find_tag_cfg(tags: Array, tag_name: String) -> Dictionary:
	for t in tags:
		if t.get("tag_name") == tag_name:
			return t
	return {}


# Returns every tag/group row currently in the list, including rows nested in
# the indent containers used for group children.
func _get_all_tag_rows() -> Array:
	var rows: Array = []
	_collect_tag_rows(%Tags, rows)
	return rows


func _collect_tag_rows(container: Node, rows: Array) -> void:
	for child in container.get_children():
		if child is AnimationTagRow or child is AnimationGroupRow:
			rows.push_back(child)
		elif child is BoxContainer or child is MarginContainer:
			_collect_tag_rows(child, rows)


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
			# Keep the user's settings from the cache, but refresh the frame data
			# from the source file (ranges may have changed between scans). The
			# frame data is only present when the tags were read with ranges.
			var cached: Dictionary = tags_cache_index[tags[i].tag_name]
			var merged: Dictionary = cached.duplicate()
			if tags[i].has("from") and tags[i].has("to"):
				merged.from = tags[i].from
				merged.to = tags[i].to
				merged.direction = tags[i].direction
			result.push_back(merged)
		else:
			# New tag: set default loop and autoplay behavior based on object type
			tags[i].loops = _get_default_loop_behavior()
			tags[i].autoplays = _get_default_autoplay_behavior()
			result.push_back(tags[i])

	return result


func _get_tags_from_ui() -> Array:
	var tags_list = []
	for tag_row in _get_all_tag_rows():
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
		# Plain tag names arrive as Strings (from --list-tags); they are wrapped
		# into dicts so the rest of the pipeline can treat every tag uniformly.
		if typeof(t) == TYPE_STRING:
			if t == PopochiuEditorHelper.EMPTY_STRING:
				continue
			tags_list.push_back({ "tag_name": t })
		elif typeof(t) == TYPE_DICTIONARY:
			if t.get("tag_name", PopochiuEditorHelper.EMPTY_STRING) == PopochiuEditorHelper.EMPTY_STRING:
				continue
			tags_list.push_back(t)
	return tags_list


# Like _get_tags_from_source but also reads the frame ranges. Only used at import
# time (it is slow, since it makes Aseprite export the sprite metadata).
func _get_tags_from_source_with_ranges() -> Array:
	var tags_found = _list_tags_with_ranges(ProjectSettings.globalize_path(_source))
	if typeof(tags_found) == TYPE_INT:
		PopochiuUtils.print_error(RESULT_CODE.get_error_message(tags_found))
		return []
	var tags_list = []
	for t in tags_found:
		# Ranges arrive as dicts (from list_tags_with_ranges), but stay safe
		# against name-only strings just in case.
		if typeof(t) == TYPE_STRING:
			if t == PopochiuEditorHelper.EMPTY_STRING:
				continue
			tags_list.push_back({ "tag_name": t })
		elif typeof(t) == TYPE_DICTIONARY:
			if t.get("tag_name", PopochiuEditorHelper.EMPTY_STRING) == PopochiuEditorHelper.EMPTY_STRING:
				continue
			tags_list.push_back(t)
	return tags_list


func _show_message(
	message: String,
	title: String = PopochiuEditorHelper.EMPTY_STRING,
	object: Object = null,
	method := PopochiuEditorHelper.EMPTY_STRING
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


func _show_confirmation(
	message: String, title: String = PopochiuEditorHelper.EMPTY_STRING
) -> ConfirmationDialog:
	var confirmation_dialog = ConfirmationDialog.new()
	get_parent().add_child(confirmation_dialog)
	if title != PopochiuEditorHelper.EMPTY_STRING:
		confirmation_dialog.title = title
	confirmation_dialog.dialog_text = message
	confirmation_dialog.popup_centered()
	confirmation_dialog.close_requested.connect(confirmation_dialog.queue_free)
	return confirmation_dialog


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
	var rows := _get_all_tag_rows()
	if rows.is_empty():
		return
		
	var all_import := true
	var none_import := true
	
	# Check all tags to determine the collective state
	for tag_row in rows:
		var cfg: Dictionary = tag_row.get_cfg()
		if not cfg.has("import"):
			continue
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
	for tag_row in _get_all_tag_rows():
		var cfg: Dictionary = tag_row.get_cfg()
		if not cfg.has(config.row_property):
			continue
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
	var seen_groups := {}
	
	for tag_row in _get_all_tag_rows():
		var toggle = tag_row.get(config.row_toggle)
		if not toggle:
			continue

		# Autoplay is exclusive within a group: when bulk-enabling autoplay,
		# only the first child of each group gets enabled
		if config.row_property == "autoplays" and toggle_state:
			var group_name: String = (
				tag_row.get_group_name() if tag_row is AnimationTagRow
				else PopochiuEditorHelper.EMPTY_STRING
			)
			if not group_name.is_empty():
				if seen_groups.has(group_name):
					tag_row.set_autoplay_no_signal(false)
					continue
				seen_groups[group_name] = true

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
