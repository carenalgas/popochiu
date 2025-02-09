@tool
extends PanelContainer

# TODO: review coding standards for those constants
const RESULT_CODE = preload("res://addons/popochiu/editor/config/result_codes.gd")
const LOCAL_OBJ_CONFIG = preload("res://addons/popochiu/editor/config/local_obj_config.gd")
# TODO: this can be specialized, even if for a two buttons... ?
const AnimationTagRow =\
preload("res://addons/popochiu/editor/importers/aseprite/docks/animation_tag_row.gd")

var scene: Node
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
var _source: String = ""
var _tags_cache: Array = []
var _file_dialog_aseprite: FileDialog
var _output_folder_dialog: FileDialog
var _importing := false
var _output_folder := ""
var _out_folder_default := "[Same as scene]"


#region Godot ######################################################################################
func _ready():
	_set_elements_styles()
	
	if not PopochiuEditorConfig.aseprite_importer_enabled():
		_show_info()
		return
	
	# Check access to Aseprite executable
	var result = _check_aseprite()
	if result == RESULT_CODE.SUCCESS:
		_show_importer()
	else:
		PopochiuUtils.print_error(RESULT_CODE.get_error_message(result))
		_show_warning()
	
	# Load inspector dock configuration from node
	var cfg = LOCAL_OBJ_CONFIG.load_config(target_node)
	if cfg == null:
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

	_output_folder = cfg.get("o_folder", "")
	get_node("%OutFolderButton").text = (
		_output_folder if _output_folder != "" else _out_folder_default
	)
	get_node("%OutFileName").text = cfg.get("o_name", "")
	get_node("%VisibleLayersCheckButton").set_pressed_no_signal(
		cfg.get("only_visible_layers", false)
	)
	get_node("%WipeOldAnimationsCheckButton").set_pressed_no_signal(
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
		"tags_exp": get_node("%Tags").visible,
		"op_exp": get_node("%Options").visible,
		"o_folder": _output_folder,
		"o_name": get_node("%OutFileName").text,
		"only_visible_layers": get_node("%VisibleLayersCheckButton").is_pressed(),
		"wipe_old_anims": get_node("%WipeOldAnimationsCheckButton").is_pressed(),
	}

	LOCAL_OBJ_CONFIG.save_config(target_node, cfg)


func _load_default_config():
	# Reset variables
	_source = ""
	_tags_cache = []
	_output_folder = ""

	# Empty tags list
	_empty_tags_container()

	# Reset inspector fields
	get_node("%SourceButton").text = "[empty]"
	get_node("%SourceButton").tooltip_text = ""
	get_node("%OutFolderButton").text = "[empty]"
	get_node("%OutFileName").clear()
	get_node("%VisibleLayersCheckButton").set_pressed_no_signal(false)
	get_node("%WipeOldAnimationsCheckButton").set_pressed_no_signal(
		PopochiuConfig.is_default_wipe_old_anims_enabled()
	)


func _set_source(source):
	_source = source
	get_node("%SourceButton").text = _source
	get_node("%SourceButton").tooltip_text = _source


func _on_source_pressed():
	_open_source_dialog()


func _on_aseprite_file_selected(path):
	_set_source(ProjectSettings.localize_path(path))
	_populate_tags(_get_tags_from_source())
	_save_config()
	_file_dialog_aseprite.queue_free()


func _on_rescan_pressed():
	_populate_tags(\
		_merge_with_cache(_get_tags_from_source())\
	)
	_save_config()


func _on_import_pressed():
	if _importing:
		return
	
	_importing = true
	_root_node = get_tree().get_edited_scene_root()
	
	if _source == "":
		_show_message("Aseprite file not selected")
		_importing = false
		return
	
	_options = {
		"source": ProjectSettings.globalize_path(_source),
		"tags": _tags_cache,
		"output_folder": (
			_output_folder if _output_folder != "" else _root_node.scene_file_path.get_base_dir()
		),
		"output_filename": get_node("%OutFileName").text,
		"only_visible_layers": get_node("%VisibleLayersCheckButton").is_pressed(),
		"wipe_old_animations": get_node("%WipeOldAnimationsCheckButton").is_pressed(),
	}
	
	_save_config()


func _on_reset_pressed():
	var _confirmation_dialog = _show_confirmation(\
		"This will reset the importer preferences." + \
		"This cannot be undone! Are you sure?", "Confirmation required!")
	_confirmation_dialog.get_ok_button().connect("pressed", Callable(self, "_reset_prefs_metadata"))


func _reset_prefs_metadata():
	if target_node.has_meta(LOCAL_OBJ_CONFIG.LOCAL_OBJ_CONFIG_META_NAME):
		target_node.remove_meta(LOCAL_OBJ_CONFIG.LOCAL_OBJ_CONFIG_META_NAME)
		_load_default_config()
		notify_property_list_changed()


func _open_source_dialog():
	_file_dialog_aseprite = _create_aseprite_file_selection()
	get_parent().add_child(_file_dialog_aseprite)
	if _source != "":
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
		if t.tag_name == "":
			continue
		
		var tag_row: AnimationTagRow = _animation_tag_row_scene.instantiate()
		get_node("%Tags").add_child(tag_row)
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
	for tl in get_node("%Tags").get_children():
		get_node("%Tags").remove_child(tl)
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
	for tag_row in get_node("%Tags").get_children():
		var tag_row_cfg = tag_row.get_cfg()
		if tag_row_cfg.tag_name == "":
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
		if t == "":
			continue
		tags_list.push_back({
			tag_name = t
		})
	return tags_list


func _show_message(
	message: String, title: String = "", object: Object = null, method := ""
):
	var warning_dialog = AcceptDialog.new()
	
	if title != "":
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


func _show_confirmation(message: String, title: String = ""):
	var _confirmation_dialog = ConfirmationDialog.new()
	get_parent().add_child(_confirmation_dialog)
	if title != "":
		_confirmation_dialog.title = title
	_confirmation_dialog.dialog_text = message
	_confirmation_dialog.popup_centered()
	_confirmation_dialog.connect("close_requested", Callable(_confirmation_dialog, "queue_free"))
	return _confirmation_dialog


func _on_options_title_toggled(button_pressed):
	_set_options_visible(button_pressed)
	_save_config()


func _set_options_visible(is_visible):
	get_node("%Options").visible = is_visible
	get_node("%OptionsTitle").icon = (
		PopochiuEditorConfig.get_icon(PopochiuEditorConfig.Icons.EXPANDED) if is_visible
		else PopochiuEditorConfig.get_icon(PopochiuEditorConfig.Icons.COLLAPSED)
	)

func _on_tags_title_toggled(button_pressed: bool) -> void:
	_set_tags_visible(button_pressed)
	_save_config()


func _set_tags_visible(is_visible: bool) -> void:
	get_node("%Tags").visible = is_visible
	get_node("%TagsTitle").icon = (
		PopochiuEditorConfig.get_icon(PopochiuEditorConfig.Icons.EXPANDED) if is_visible
		else PopochiuEditorConfig.get_icon(PopochiuEditorConfig.Icons.COLLAPSED)
	)

func _on_out_folder_pressed():
	_output_folder_dialog = _create_output_folder_selection()
	get_parent().add_child(_output_folder_dialog)
	if _output_folder != _out_folder_default:
		_output_folder_dialog.current_dir = _output_folder
	_output_folder_dialog.popup_centered_ratio()


func _create_output_folder_selection():
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.title = "Select destination folder"
	file_dialog.connect("dir_selected", Callable(self, "_on_output_folder_selected"))
	return file_dialog


func _on_output_folder_selected(path):
	_output_folder = path
	get_node("%OutFolderButton").text = (
		_output_folder if _output_folder != "" else _out_folder_default
	)
	_output_folder_dialog.queue_free()
	_save_config()


func _set_elements_styles():
	# Set sections title colors according to current theme
	var section_color = get_theme_color("prop_section", "Editor")
	var section_style = StyleBoxFlat.new()
	section_style.set_bg_color(section_color)
	get_node("%TagsTitleBar").set("theme_override_styles/panel", section_style)
	get_node("%OptionsTitleBar").set("theme_override_styles/panel", section_style)

	# Set style of warning panel
	get_node("%WarningPanel").add_theme_stylebox_override(
		"panel",
		get_node("%WarningPanel").get_theme_stylebox("sub_inspector_bg11", "Editor")
	)
	get_node("%WarningLabel").add_theme_color_override("font_color", Color("c46c71"))


func _show_info():
	get_node("%Info").visible = true
	get_node("%Warning").visible = false
	get_node("%Importer").visible = false


func _show_warning():
	get_node("%Info").visible = false
	get_node("%Warning").visible = true
	get_node("%Importer").visible = false
	

func _show_importer():
	get_node("%Info").visible = false
	get_node("%Warning").visible = false
	get_node("%Importer").visible = true

# TODO: Introduce layer selection list, more or less as tags


#endregion
