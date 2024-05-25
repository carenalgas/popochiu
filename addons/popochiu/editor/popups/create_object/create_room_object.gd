@tool
extends "res://addons/popochiu/editor/popups/create_object/create_object.gd"

var _room: Node2D = null
var _group_folder := ""


#region Godot ######################################################################################
func _init() -> void:
	_info_folder = "In [b]%s[/b] the following files will be created:\n\n"
	_info_files = "[code]- &t_&n.tscn\n- &t_&n.gd[/code]"


func _ready() -> void:
	if PopochiuEditorHelper.is_room(EditorInterface.get_edited_scene_root()):
		_room = EditorInterface.get_edited_scene_root()
		_group_folder = _room.scene_file_path.get_base_dir().path_join(_group_folder + "/%s")
		_info_folder = _info_folder % _group_folder.replace("/%s", "/&n")
	
	super()


#endregion
