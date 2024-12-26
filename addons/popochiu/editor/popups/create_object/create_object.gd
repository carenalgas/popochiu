@tool
extends Control

signal content_changed

@export var title := ""

var _info_folder := "In [b]%s[/b] the following files will be created:\n\n"
var _info_files := "[code]- &t_&n.tscn\n- &t_&n.gd\n- &t_&n.tres\n- &t_&n_state.gd[/code]"
var _info_text := ""
var _name := ""
var _target_folder := ""
var _dflt_size := Vector2.ZERO

@onready var input: LineEdit = %Input
@onready var error_container: HBoxContainer = %ErrorContainer
@onready var error_icon: TextureRect = %ErrorIcon
@onready var error_feedback: Label = %ErrorFeedback
@onready var info: RichTextLabel = %Info


#region Godot ######################################################################################
func _ready() -> void:
	_info_text = _info_folder + _info_files
	
	# Connect to children's signals
	input.text_changed.connect(_update_name)
	
	error_container.hide()


#endregion

#region Virtual ####################################################################################
func _create() -> Object:
	return null


func _on_about_to_popup() -> void:
	pass


func _set_info_text() -> void:
	pass


#endregion

#region Public #####################################################################################
func on_about_to_popup() -> void:
	PopochiuEditorHelper.override_font(info, "normal_font", "main")
	PopochiuEditorHelper.override_font(info, "bold_font", "bold")
	PopochiuEditorHelper.override_font(info, "mono_font", "source")
	
	error_icon.texture = get_theme_icon("StatusError", "EditorIcons")
	error_feedback.add_theme_color_override("font_color", get_theme_color("error_color", "Editor"))
	
	_on_about_to_popup()
	await get_tree().process_frame
	
	_dflt_size = get_child(0).size
	content_changed.emit()


func create() -> void:
	var created_object := await _create()
	if not created_object or not is_instance_valid(created_object):
		return
	await PopochiuEditorHelper.filesystem_scanned()
	
	# Open the scene in the editor and select the file in the FileSystem dock ----------------------
	if created_object is Node:
		EditorInterface.select_file(created_object.scene_file_path)
		EditorInterface.open_scene_from_path(created_object.scene_file_path)
	else:
		EditorInterface.select_file(created_object.resource_path)
		EditorInterface.edit_resource(load(created_object.resource_path))


#endregion

#region Private ####################################################################################
func _update_name(new_text: String) -> void:
	if error_container.visible:
		error_container.hide()
	
	_name = new_text.to_pascal_case()
	if _name.is_empty():
		info.text = ""
		info.hide()
	else:
		_set_info_text()
		info.show()
	
	# Check if another object with the same name is already created
	if DirAccess.dir_exists_absolute(_target_folder):
		error_feedback.text = "Another object with that name already exists!"
		error_container.show()
	
	_info_updated()
	(get_parent() as ConfirmationDialog).get_ok_button().disabled = error_container.visible


func _info_updated() -> void:
	await get_tree().process_frame
	
	get_child(0).size.y = _dflt_size.y
	content_changed.emit()


#endregion
