tool
extends PanelContainer

const result_code = preload("../config/result_codes.gd")

const AnimationCreator = preload("../animation_creator.gd")
const AnimationTagRow = preload("./animation_tag_row.gd")
const local_obj_config = preload("../config/local_obj_config.gd")

var animation_creator: AnimationCreator
var _animation_tag_row_scene: PackedScene = preload('./animation_tag_row.tscn')

var scene: Node
var target_node: Node

var config
var file_system: EditorFileSystem

var _source: String = ""
var _tags_cache: Array = []
var _animation_player_path: String
var _file_dialog_aseprite: FileDialog
var _output_folder_dialog: FileDialog
var _importing := false

var _output_folder := ""
var _out_folder_default := "[Same as scene]"

# Source info fields
onready var _source_field = $margin/VBoxContainer/source/button
onready var _rescan_source_button = $margin/VBoxContainer/source/rescan
onready var _tags_ui_container = $margin/VBoxContainer/tags
# Importer options fields
onready var _options_title = $margin/VBoxContainer/options_title/options_title
onready var _options_container = $margin/VBoxContainer/options
onready var _out_folder_field = $margin/VBoxContainer/options/out_folder/button
onready var _out_filename_field = $margin/VBoxContainer/options/out_filename/LineEdit
onready var _visible_layers_field =  $margin/VBoxContainer/options/visible_layers/CheckButton


func _ready():
	if not target_node.has_node("AnimationPlayer"):
		printerr(result_code.get_error_message(result_code.ERR_NO_ANIMATION_PLAYER_FOUND))
	_animation_player_path = target_node.get_node("AnimationPlayer").get_path()

	# Instantiate animation creator
	animation_creator = AnimationCreator.new()
	animation_creator.init(config, file_system)

	# Load inspector dock configuration from node
	var cfg = local_obj_config.load_config(target_node)
	if cfg == null:
		_load_default_config()
	else:
		_load_config(cfg)
	

func _load_config(cfg):
	if cfg.has("source"):
		_set_source(cfg.source)

	_output_folder = cfg.get("o_folder", "")
	_out_folder_field.text = _output_folder if _output_folder != "" else _out_folder_default
	_out_filename_field.text = cfg.get("o_name", "")
	_visible_layers_field.pressed = cfg.get("only_visible", false)

	_set_options_visible(cfg.get("op_exp", false))
	_populate_tags(cfg.get("tags", []))


func _save_config():
	_update_tags_cache()
	var cfg := {
		"player": _animation_player_path,
		"source": _source,
		"tags": _tags_cache,
		"op_exp": _options_title.pressed,
		"o_folder": _output_folder,
		"o_name": _out_filename_field.text,
		"only_visible": _visible_layers_field.pressed,
	}

	local_obj_config.save_config(target_node, cfg)


func _load_default_config():
	_set_options_visible(false)


func _set_source(source):
	_source = source
	_source_field.text = _source
	_source_field.hint_tooltip = _source


func _on_source_pressed():
	_open_source_dialog()


func _on_aseprite_file_selected(path):
	_set_source(ProjectSettings.localize_path(path))
	_populate_tags(_get_tags_from_source())
	_save_config()
	_file_dialog_aseprite.queue_free()


func _on_rescan_pressed():
	_populate_tags(_get_tags_from_source())
	_save_config()


func _on_import_pressed():
	if _importing:
		return
	_importing = true

	var root = get_tree().get_edited_scene_root()

	if _animation_player_path == "" or not root.has_node(_animation_player_path):
		_show_message("AnimationPlayer not found")
		_importing = false
		return

	if _source == "":
		_show_message("Aseprite file not selected")
		_importing = false
		return

	var options = {
		"source": ProjectSettings.globalize_path(_source),
		"tags": _tags_cache,
		"output_folder": _output_folder if _output_folder != "" else root.filename.get_base_dir(),
		"output_filename": _out_filename_field.text,
		"only_visible_layers": _visible_layers_field.pressed,
	}

	_save_config()

	animation_creator.create_animations(target_node, root.get_node(_animation_player_path), options)
	_importing = false


func _open_source_dialog():
	_file_dialog_aseprite = _create_aseprite_file_selection()
	get_parent().add_child(_file_dialog_aseprite)
	if _source != "":
		_file_dialog_aseprite.current_dir = _source.get_base_dir()
	_file_dialog_aseprite.popup_centered_ratio()


func _create_aseprite_file_selection():
	var file_dialog = FileDialog.new()
	file_dialog.mode = FileDialog.MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.connect("file_selected", self, "_on_aseprite_file_selected")
	file_dialog.set_filters(PoolStringArray(["*.ase","*.aseprite"]))
	return file_dialog


func _populate_tags(tags: Array):
	# Clean the list empty
	for tl in _tags_ui_container.get_children():
		_tags_ui_container.remove_child(tl)
		tl.queue_free()
	
	# Add each tag found
	for t in tags:
		if t.tag_name == "":
			continue
		
		var tag_row: AnimationTagRow = _animation_tag_row_scene.instance()
		_tags_ui_container.add_child(tag_row)
		tag_row.init(config, t)
		tag_row.connect("tag_state_changed", self, "_save_config")
		
	_update_tags_cache()


func _update_tags_cache():
	_tags_cache = _get_tags_from_ui()


func _get_tags_from_ui() -> Array:
	var tags_list = []
	for tag_row in _tags_ui_container.get_children():
		var tag_row_cfg = tag_row.get_cfg()
		if tag_row_cfg.tag_name == "":
			continue
		tags_list.push_back(tag_row_cfg)
	return tags_list


func _get_tags_from_source() -> Array:
	var tags_found = animation_creator.list_tags(ProjectSettings.globalize_path(_source))
	var tags_list = []
	for t in tags_found:
		if t == "":
			continue
		tags_list.push_back({
			"tag_name": t
		})
	return tags_list


func _show_message(message: String):
	var _warning_dialog = AcceptDialog.new()
	get_parent().add_child(_warning_dialog)
	_warning_dialog.dialog_text = message
	_warning_dialog.popup_centered()
	_warning_dialog.connect("popup_hide", _warning_dialog, "queue_free")


func _on_options_title_toggled(button_pressed):
	_set_options_visible(button_pressed)
	_save_config()


func _set_options_visible(is_visible):
	_options_container.visible = is_visible
	_options_title.icon = config.get_icon("expanded") if is_visible else config.get_icon("collapsed")


func _on_out_folder_pressed():
	_output_folder_dialog = _create_output_folder_selection()
	get_parent().add_child(_output_folder_dialog)
	if _output_folder != _out_folder_default:
		_output_folder_dialog.current_dir = _output_folder
	_output_folder_dialog.popup_centered_ratio()


func _create_output_folder_selection():
	var file_dialog = FileDialog.new()
	file_dialog.mode = FileDialog.MODE_OPEN_DIR
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.connect("dir_selected", self, "_on_output_folder_selected")
	return file_dialog


func _on_output_folder_selected(path):
	_output_folder = path
	_out_folder_field.text = _output_folder if _output_folder != "" else _out_folder_default
	_output_folder_dialog.queue_free()


## TODO: Introduce layer selection list, more or less as tags

## TODO: IMPORTANT AND FIRST IN LINE! The importer has different behavior for Characters, Rooms and Inventory items!
