@tool
extends PanelContainer

# TODO: review coding standards for those constants
const RESULT_CODE = preload("res://addons/popochiu/editor/config/result_codes.gd")
const LOCAL_OBJ_CONFIG = preload("res://addons/popochiu/editor/config/local_obj_config.gd")
# TODO: this can be specialized, even if for a two buttons... ?
const AnimationTagRow =\
preload("res://addons/popochiu/editor/importers/aseprite/docks/animation_tag_row.gd")

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
var _tags_cache: Array = []
var _file_dialog_aseprite: FileDialog
var _output_folder_dialog: FileDialog
var _importing := false
var _output_folder := PopochiuEditorHelper.EMPTY_STRING
var _out_folder_default := "[Same as scene]"


#region Public ######################################################################################
func init():
	# Connect to theme changes to update styles if the user
	# sets a different theme for the editor.
	# Doing it once becase we have more docks initialized.
	if not is_connected("theme_changed", _on_theme_changed):
		theme_changed.connect(_on_theme_changed)

	# Initialize styles and UI elements visibility
	_set_elements_styles()
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
		_set_options_visible(true)
	else:
		_load_config(cfg)
		_set_tags_visible(cfg.get("tags_exp"))
		_set_options_visible(cfg.get("op_exp"))


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

	_output_folder = cfg.get("o_folder", PopochiuEditorHelper.EMPTY_STRING)
	%OutFolderButton.text = (
		_output_folder if _output_folder != PopochiuEditorHelper.EMPTY_STRING else _out_folder_default
	)
	%OutFileName.text = cfg.get("o_name", PopochiuEditorHelper.EMPTY_STRING)
	%VisibleLayersCheckButton.set_pressed_no_signal(
		cfg.get("only_visible_layers", false)
	)
	%WipeOldAnimationsCheckButton.set_pressed_no_signal(
		cfg.get("wipe_old_anims", false)
	)

	_set_tags_visible(cfg.get("tags_exp", false))
	_set_options_visible(cfg.get("op_exp", false))
	_populate_tags(cfg.get("tags", []))


func _save_config():
	_update_tags_cache()
	
	var cfg := {
		"source": _source,
		"tags": _tags_cache,
		"tags_exp": %Tags.visible,
		"op_exp": %Options.visible,
		"o_folder": _output_folder,
		"o_name": %OutFileName.text,
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
	%OutFolderButton.text = "[empty]"
	%OutFileName.clear()
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
	_populate_tags(_get_tags_from_source())
	_save_config()
	_file_dialog_aseprite.queue_free()
	_set_tags_visible(true)


func _on_rescan_pressed():
	_populate_tags(\
		_merge_with_cache(_get_tags_from_source())\
	)
	_save_config()
	_set_tags_visible(true)


func _on_import_pressed():
	if _importing:
		return
	
	_importing = true
	_root_node = get_tree().get_edited_scene_root()

	if _output_folder == PopochiuEditorHelper.EMPTY_STRING:
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
		"output_filename": %OutFileName.text,
		"only_visible_layers": %VisibleLayersCheckButton.is_pressed(),
		"wipe_old_animations": %WipeOldAnimationsCheckButton.is_pressed(),
	}

	_save_config()


func _on_reset_pressed():
	var _confirmation_dialog = _show_confirmation(\
		"This will reset the importer preferences." + \
		"This cannot be undone! Are you sure?", "Confirmation required!")
	_confirmation_dialog.get_ok_button().connect("pressed", Callable(self, "_reset_prefs_metadata"))


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
		_customize_tag_ui(tag_row)
		# Invoke customization hook implementable in child classes		
	_update_tags_cache()


func _customize_tag_ui(tagrow: AnimationTagRow):
	## This can be implemented by child classes if necessary
	pass


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
		result.push_back(
			tags_cache_index[tags[i].tag_name]
			if tags_cache_index.has(tags[i].tag_name)
			else tags[i]
		)

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


func _on_options_title_toggled(button_pressed):
	_set_options_visible(!button_pressed)
	_save_config()


func _set_options_visible(is_visible):
	%Options.visible = is_visible
	%OptionsTitle.icon = (
		PopochiuEditorConfig.get_icon(PopochiuEditorConfig.Icons.EXPANDED) if is_visible
		else PopochiuEditorConfig.get_icon(PopochiuEditorConfig.Icons.COLLAPSED)
	)

func _on_tags_title_toggled(button_pressed: bool) -> void:
	_set_tags_visible(!button_pressed)
	_save_config()


func _set_tags_visible(is_visible: bool) -> void:
	# If the tags container is empty, we show an info box
	%TagsInfo.visible = %Tags.get_child_count() == 0

	%TagsScrollContainer.visible = is_visible
	%TagsTitle.icon = (
		PopochiuEditorConfig.get_icon(PopochiuEditorConfig.Icons.EXPANDED) if is_visible
		else PopochiuEditorConfig.get_icon(PopochiuEditorConfig.Icons.COLLAPSED)
	)

func _on_out_folder_pressed():
	_output_folder_dialog = _create_output_folder_selection()
	get_parent().add_child(_output_folder_dialog)
	if _output_folder != _out_folder_default:
		_output_folder_dialog.current_dir = _output_folder
	_output_folder_dialog.popup_centered_ratio()


# Called when the editor theme changes to update UI styling.
func _on_theme_changed():
	# Defer the style update to ensure theme cache is fully updated.
	call_deferred("_set_elements_styles")


func _create_output_folder_selection():
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.title = "Select destination folder"
	file_dialog.connect("dir_selected", Callable(self, "_on_output_folder_selected"))
	return file_dialog


func _on_output_folder_selected(path):
	_output_folder = path
	%OutFolderButton.text = (
		_output_folder if _output_folder != PopochiuEditorHelper.EMPTY_STRING else _out_folder_default
	)
	_output_folder_dialog.queue_free()
	_save_config()


func _set_elements_styles():
	# Use the editor's section stylebox and remove borders to maintain theme consistency
	var section_style = get_theme_stylebox("normal", "Button").duplicate()
	section_style.set_border_width_all(0)
	section_style.set_content_margin_all(0)

	%TagsTitleBar.add_theme_stylebox_override("panel", section_style)
	%OptionsTitleBar.add_theme_stylebox_override("panel", section_style)

	# Set style of warning panel
	%WarningLabel.add_theme_color_override("font_color", get_theme_color("error_color", "Editor"))

	# Style the title buttons with proper theme colors
	var normal_color = get_theme_color("font_color", "Label")
	var hover_color = get_theme_color("font_hover_color", "Button")
	var pressed_color = get_theme_color("font_pressed_color", "Button")

	# Apply colors to both title buttons
	for button in [%TagsTitle, %OptionsTitle]:
		button.add_theme_color_override("font_color", normal_color)
		button.add_theme_color_override("font_hover_color", hover_color)
		button.add_theme_color_override("font_pressed_color", pressed_color)
		button.add_theme_color_override("font_focus_color", pressed_color)

		# Ensure button background is transparent
		var button_style = StyleBoxEmpty.new()
		button.add_theme_stylebox_override("normal", button_style)
		button.add_theme_stylebox_override("hover", button_style)
		button.add_theme_stylebox_override("pressed", button_style)
		button.add_theme_stylebox_override("focus", button_style)

	%Import.set_button_icon(get_theme_icon("MoveDown", "EditorIcons"))
	%Reset.set_button_icon(get_theme_icon("Clear", "EditorIcons"))


func _show_warning():
	%Warning.visible = true
	%Importer.visible = false
	

func _show_importer():
	%Warning.visible = false
	%Importer.visible = true

# TODO: Introduce layer selection list, more or less as tags


#endregion
