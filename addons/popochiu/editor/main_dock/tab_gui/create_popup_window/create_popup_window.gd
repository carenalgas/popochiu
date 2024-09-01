@tool
extends AcceptDialog

const POPOCHIU_POPUP_SCENE :=\
"res://addons/popochiu/engine/objects/gui/components/popups/popochiu_popup.tscn"
const POPOCHIU_POPUP_SCRIPT :=\
"res://addons/popochiu/engine/templates/gui/popup_template.gd"
const POPUPS_FOLDER := "res://game/gui/popups/%s/"

var _popup_id := ""
var _scene_path := POPUPS_FOLDER + "%s.tscn"
var _script_path := POPUPS_FOLDER + "%s.gd"

@onready var title_edit: LineEdit = %TitleEdit
@onready var info: RichTextLabel = %Info
@onready var dflt_info := info.text

#region Godot ######################################################################################
func _ready() -> void:
	# Connect to own signals
	about_to_popup.connect(_on_about_to_popup)
	
	# Connect to childs signals
	title_edit.text_changed.connect(_on_title_changed)
	get_ok_button().pressed.connect(_create_popup)
	
	info.hide()
	hide()


#endregion

#region Private ####################################################################################
func _on_about_to_popup() -> void:
	title_edit.clear()
	info.text = dflt_info
	info.hide()


func _on_title_changed(new_text: String) -> void:
	if new_text.is_empty():
		info.hide()
		return
	
	_popup_id = new_text.to_snake_case()
	
	info.text = dflt_info.replace("%s", _popup_id)
	info.show()


func _create_popup() -> void:
	# Create the popups directory inside the graphic interface directory ---------------------------
	DirAccess.make_dir_recursive_absolute(POPUPS_FOLDER % _popup_id)
	
	var scene_path := _scene_path.replace("%s", _popup_id)
	var script_path := _script_path.replace("%s", _popup_id)
	var pascal_name := _popup_id.to_pascal_case()
	
	# Create the popup script ----------------------------------------------------------------------
	DirAccess.copy_absolute(POPOCHIU_POPUP_SCRIPT, script_path)
	
	# Create the PopochiuPopup scene ---------------------------------------------------------------
	var popup_instance: PopochiuPopup = load(POPOCHIU_POPUP_SCENE).instantiate()
	popup_instance.set_script(load(script_path))
	popup_instance.name = pascal_name + "Popup"
	popup_instance.script_name = pascal_name
	popup_instance.title = pascal_name.capitalize()
	
	var popup_scene: PackedScene = PackedScene.new()
	popup_scene.pack(popup_instance)
	if ResourceSaver.save(popup_scene, scene_path) != OK:
		PopochiuUtils.print_error("Couldn't create popup: %s" % _popup_id)
		# TODO: Show feedback in the popup
		return
	
	# Add the popup to the Popups node in the graphic interface scene ------------------------------
	var popup_node: PopochiuPopup = load(scene_path).instantiate()
	var gui_node := EditorInterface.get_edited_scene_root()
	
	gui_node.get_node("Popups").add_child(popup_node)
	popup_node.owner = gui_node
	EditorInterface.save_scene()
	
	# Open the scene of the created popup for edition ----------------------------------------------
	await PopochiuEditorHelper.filesystem_scanned()
	
	EditorInterface.select_file(scene_path)
	EditorInterface.open_scene_from_path(scene_path)


#endregion
