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

#region Public ######################################################################################
func init():
	# Connect to theme changes to update styles if the user
	# sets a different theme for the editor.
	# Doing it once becase we have more docks initialized.
	if not is_connected("theme_changed", _on_theme_changed):
		theme_changed.connect(_on_theme_changed)
	
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

	# Connect signals
	%FilterField.text_changed.connect(_on_filter_text_changed)


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
func _customize_tag_ui(tagrow: AnimationTagRow):
	## This can be implemented by child classes if necessary
	pass

# This method can be overridden by child classes to customize the filter bar UI,
# such as enabling additional buttons or similar.
func _customize_filter_ui():
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


#region Private ####################################################################################
func _check_aseprite() -> int:
	if not _aseprite.check_command_path():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FULL_PATH
	
	if not _aseprite.test_command():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FOUND
	
	return RESULT_CODE.SUCCESS	


## Filters the tag list based on the search text in the FilterField.
## Tags whose names contain the search string (case-insensitive, ignoring spaces) will be shown.
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


func _list_tags(file: String):
	if not _aseprite.check_command_path():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FULL_PATH
	if not _aseprite.test_command():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FOUND
	return _aseprite.list_tags(file)


## TODO: Currently unused. keeping this as reference
## to populate a checkable list of layers
func _list_layers(file: String, only_visibles = false):
	if not _aseprite.check_command_path():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FULL_PATH
	if not _aseprite.test_command():
		return RESULT_CODE.ERR_ASEPRITE_CMD_NOT_FOUND
	return _aseprite.list_layers(file, only_visibles)


func _load_config(cfg):
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


func _save_config():
	_update_tags_cache()
	
	var cfg := {
		"source": _source,
		"tags": _tags_cache,
		"tags_exp": %Tags.visible,
		"only_visible_layers": %VisibleLayersCheckButton.is_pressed(),
		"wipe_old_anims": %WipeOldAnimationsCheckButton.is_pressed(),
	}

	LOCAL_OBJ_CONFIG.save_config(target_node, cfg)


func _load_default_config():
	# Reset variables
	_source = PopochiuEditorHelper.EMPTY_STRING
	_tags_cache = []
	_output_folder = PopochiuEditorHelper.EMPTY_STRING

	# Empty tags list
	_empty_tags_container()

	# Reset inspector fields
	%SourceButton.text = "[empty]"
	%SourceButton.tooltip_text = PopochiuEditorHelper.EMPTY_STRING
	%VisibleLayersCheckButton.set_pressed_no_signal(false)
	%WipeOldAnimationsCheckButton.set_pressed_no_signal(
		PopochiuConfig.is_default_wipe_old_anims_enabled()
	)


func _set_source(source):
	_source = source
	%SourceButton.text = _source
	%SourceButton.tooltip_text = _source


func _on_source_pressed():
	_open_source_dialog()


func _on_aseprite_file_selected(path):
	_set_source(ProjectSettings.localize_path(path))
	_scan_source()
	_file_dialog_aseprite.queue_free()


func _on_rescan_pressed():
	_scan_source()


func _on_import_pressed():
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


func _on_reset_pressed():
	var _confirmation_dialog = _show_confirmation(\
		"This will reset the importer preferences. " + \
		"This cannot be undone! Are you sure?", "Confirmation required!")
	_confirmation_dialog.get_ok_button().connect("pressed", Callable(self, "_reset_prefs_metadata"))


func _on_request_delete_anim(tag_name: String) -> void:
	var delete_dialog = PopochiuEditorHelper.DELETE_CONFIRMATION_SCENE.instantiate()
	
	delete_dialog.title = "Remove animation for tag %s?" % tag_name
	delete_dialog.message = "This will [b]NOT[/b] remove [b]%s[/b] prop or inventory item, but only the %s animation!" % [tag_name, tag_name.to_snake_case()]
	delete_dialog.ask = "Remove the animation for tag [b]%s[/b]?" % tag_name
	delete_dialog.on_confirmed = _delete_animation_for_tag.bind(tag_name)
	
	PopochiuEditorHelper.show_delete_confirmation(delete_dialog)


func _reset_prefs_metadata():
	LOCAL_OBJ_CONFIG.remove_config(target_node)
	_load_default_config()
	notify_property_list_changed()
	_set_tags_visible(false)


func _open_source_dialog():
	_file_dialog_aseprite = _create_aseprite_file_selection()
	get_parent().add_child(_file_dialog_aseprite)
	if _source != PopochiuEditorHelper.EMPTY_STRING:
		_file_dialog_aseprite.set_current_dir(
			ProjectSettings.globalize_path(
				_source.get_base_dir()
			)
		)
	_file_dialog_aseprite.popup_centered_ratio()


func _create_aseprite_file_selection():
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.title = "Select Aseprite animation file"
	file_dialog.connect("file_selected", Callable(self, "_on_aseprite_file_selected"))
	file_dialog.set_filters(PackedStringArray(["*.ase","*.aseprite"]))
	return file_dialog


func _scan_source():
	_populate_tags(
		_merge_with_cache(_get_tags_from_source())\
	)
	_save_config()
	_set_tags_visible(true)


func _populate_tags(tags: Array):
	## reset tags container
	_empty_tags_container()

	# Add each tag found
	for t in tags:
		if t.tag_name == PopochiuEditorHelper.EMPTY_STRING:
			continue
		
		var tag_row: AnimationTagRow = _animation_tag_row_scene.instantiate()
		%Tags.add_child(tag_row)
		tag_row.init(t)
		tag_row.connect("tag_state_changed", Callable(self, "_save_config"))
		tag_row.connect("tag_selected", Callable(self, "_on_tag_selected"))
		tag_row.connect("request_delete_anim", Callable(self, "_on_request_delete_anim"))
		_customize_tag_ui(tag_row)
		# Invoke customization hook implementable in child classes		
	_update_tags_cache()


func _on_tag_selected(tag_name: String) -> void:
	# Call the strategy-specific implementation
	_select_animation(tag_name)


func _empty_tags_container():
	# Clean the inspector tags container empty
	for tl in %Tags.get_children():
		%Tags.remove_child(tl)
		tl.queue_free()


func _update_tags_cache():
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
):
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


func _show_confirmation(message: String, title: String = PopochiuEditorHelper.EMPTY_STRING):
	var _confirmation_dialog = ConfirmationDialog.new()
	get_parent().add_child(_confirmation_dialog)
	if title != PopochiuEditorHelper.EMPTY_STRING:
		_confirmation_dialog.title = title
	_confirmation_dialog.dialog_text = message
	_confirmation_dialog.popup_centered()
	_confirmation_dialog.connect("close_requested", Callable(_confirmation_dialog, "queue_free"))
	return _confirmation_dialog


func _set_tags_visible(is_visible: bool) -> void:
	# If the tags container is empty, we show an info box
	%TagsInfo.visible = %Tags.get_child_count() == 0
	%FilterBulkBtnContainer.visible = is_visible && %Tags.get_child_count() > 0
	%TagsScrollContainer.visible = is_visible


# Called when the editor theme changes to update UI styling.
func _on_theme_changed():
	# Defer the style update to ensure theme cache is fully updated.
	call_deferred("_set_elements_styles")


func _set_elements_styles():
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

func _show_warning():
	%Warning.visible = true
	%Importer.visible = false
	

func _show_importer():
	%Warning.visible = false
	%Importer.visible = true


func _handle_animation_in_player(tag_name: String, animation_player: AnimationPlayer, action: int = HANDLE_ANIM_SELECT):
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


# TODO: Introduce layer selection list, more or less as tags
