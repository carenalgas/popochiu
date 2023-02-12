tool
extends PanelContainer

## TODO: Understand where to put this, prolly into
##       a section of Popochiu Config

## AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA - Siamo a questo punto, manca da spostare
## la configurazione. Metterla dentro ai PopochiuSettings per il momento.

#const wizard_config = preload("../../config/wizard_config.gd")

## Come carico la configurazione dalle risorse di popochiu?


const result_code = preload("../config/result_codes.gd")

const AnimationCreator = preload("../animation_creator.gd")
const local_obj_config = preload("../config/local_obj_config.gd")

var animation_creator: AnimationCreator

var scene: Node
var target_node: Node

var config
var file_system: EditorFileSystem

var _layer: String = ""
var _source: String = ""
var _animation_player_path: String
var _file_dialog_aseprite: FileDialog
var _output_folder_dialog: FileDialog
var _importing := false

var _output_folder := ""
var _out_folder_default := "[Same as scene]"
var _layer_default := "[all]"

onready var _source_field = $margin/VBoxContainer/source/button
onready var _layer_field = $margin/VBoxContainer/layer/options
onready var _options_title = $margin/VBoxContainer/options_title/options_title
onready var _options_container = $margin/VBoxContainer/options
onready var _out_folder_field = $margin/VBoxContainer/options/out_folder/button
onready var _out_filename_field = $margin/VBoxContainer/options/out_filename/LineEdit
onready var _visible_layers_field =  $margin/VBoxContainer/options/visible_layers/CheckButton
onready var _ex_pattern_field = $margin/VBoxContainer/options/ex_pattern/LineEdit
onready var _cleanup_hide_unused_nodes =  $margin/VBoxContainer/options/auto_visible_track/CheckButton


func _ready():
	## TODO: this can be Popochiu config
	if not has_node("AnimationPlayer"):
		printerr(result_code.get_error_message(result_code.ERR_NO_ANIMATION_PLAYER_FOUND))
	_animation_player_path = $AnimationPlayer.get_path()

	## TODO: this portion is loading the configuration for the SPECIFIC
	##       node (say: a PopochiuCharacter, for example) so the aseprite
	##       source path, specific preferences, etc.

	var cfg = local_obj_config.load_config(target_node)
	if cfg == null:
		_load_default_config()
	else:
		_load_config(cfg)

	animation_creator = AnimationCreator.new()
	animation_creator.init(config, file_system)


func _load_config(cfg):
	if cfg.has("source"):
		_set_source(cfg.source)

	if cfg.get("layer", "") != "":
		_set_layer(cfg.layer)

	_output_folder = cfg.get("o_folder", "")
	_out_folder_field.text = _output_folder if _output_folder != "" else _out_folder_default
	_out_filename_field.text = cfg.get("o_name", "")
	_visible_layers_field.pressed = cfg.get("only_visible", false)
	_ex_pattern_field.text = cfg.get("o_ex_p", "")
	_cleanup_hide_unused_nodes.pressed = cfg.get("set_vis_track", config.is_set_visible_track_automatically_enabled())

	_set_options_visible(cfg.get("op_exp", false))


func _load_default_config():
	_ex_pattern_field.text = config.get_default_exclusion_pattern()
	_cleanup_hide_unused_nodes.pressed = config.is_set_visible_track_automatically_enabled()
	_set_options_visible(false)


func _set_source(source):
	_source = source
	_source_field.text = _source
	_source_field.hint_tooltip = _source


func _set_layer(layer):
	_layer = layer
	_layer_field.add_item(_layer)

## TODO: valutare se non zappare pure questa. Se possibile potremmo usare un 
##       dropdown con dei checkbox, altrimenti via via via
func _on_layer_pressed():
	if _source == "":
		_show_message("Please. Select source file first.")
		return

	var layers = animation_creator.list_layers(ProjectSettings.globalize_path(_source))
	var current = 0
	_layer_field.clear()
	_layer_field.add_item("[all]")

	for l in layers:
		if l == "":
			continue

		_layer_field.add_item(l)
		if l == _layer:
			current = _layer_field.get_item_count() - 1
	_layer_field.select(current)

## TODO vedi sopra
func _on_layer_item_selected(index):
	if index == 0:
		_layer = ""
		return
	_layer = _layer_field.get_item_text(index)
	_save_config()


func _on_source_pressed():
	_open_source_dialog()


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
		"output_folder": _output_folder if _output_folder != "" else root.filename.get_base_dir(),
		"exception_pattern": _ex_pattern_field.text,
		"only_visible_layers": _visible_layers_field.pressed,
		"output_filename": _out_filename_field.text,
		"cleanup_hide_unused_nodes": _cleanup_hide_unused_nodes.pressed,
		"layer": _layer ## TODO: levala
	}

	_save_config()

	animation_creator.create_animations(target_node, root.get_node(_animation_player_path), options)
	_importing = false


func _save_config():
	var cfg := {
		"player": _animation_player_path,
		"source": _source,
		"layer": _layer,
		"op_exp": _options_title.pressed,
		"o_folder": _output_folder,
		"o_name": _out_filename_field.text,
		"only_visible": _visible_layers_field.pressed,
		"o_ex_p": _ex_pattern_field.text,
	}

	## TODO: capire questa perchè non ho capito manco cosa serve questa impostazione delle visible_track
	if _cleanup_hide_unused_nodes.pressed != config.is_set_visible_track_automatically_enabled():
		cfg["set_vis_track"] = _cleanup_hide_unused_nodes.pressed

	local_obj_config.save_config(target_node, config.is_use_metadata_enabled(), cfg)


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


func _on_aseprite_file_selected(path):
	_set_source(ProjectSettings.localize_path(path))
	_save_config()
	_file_dialog_aseprite.queue_free()


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


## TODO: Aggiungere tutta la gestione dei tag trovati, quindi creare nuove componenti con l'elenco
## dei tag e i pulsanti su ogni riga per fare quel che c'è da fare.