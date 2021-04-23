tool
extends WindowDialog


onready var body : VBoxContainer = $MarginContainer/Body

onready var edited_scene_view : Container = body.get_node('EditedSceneView')
onready var scene_tree : Tree = edited_scene_view.get_node('SceneTree')

onready var footer : HBoxContainer = body.get_node('Footer')
onready var confirm_button : Button = footer.get_node('ConfirmButton')
onready var cancel_button : Button = footer.get_node('CancelButton')

onready var alert_dialog : AcceptDialog = $AlertDialog


enum Columns {
	NAME,
	PATH,
}


const MSG_EMPTY_SCENE = 'The current scene is empty!'
const MSG_UNSAVED_SCENE = 'The current scene is still not saved!'
const MSG_NO_FILTERED_NODES_IN_SCENE  = "There aren't any %s nodes in the current scene"

const WINDOW_TITLE_DEFAULT = 'Select a Node'
const WINDOW_TITLE_WITH_FILTER = "Select the %s Node"

const DISABLED_ICON_MODULATE := Color(1, 1, 1, .5)


var class_filters : Array setget set_class_filters
var edited_scene_root : Node


var _editor_theme : EditorTheme


signal node_selected(selected_node)


func _ready():
	self.class_filters = class_filters

	scene_tree.columns = Columns.size()
	scene_tree.set_column_expand(Columns.PATH, false)

	alert_dialog.set_as_toplevel(true)

	scene_tree.connect('item_activated', self, '_on_node_selected')
	confirm_button.connect('pressed', self, '_on_node_selected')
	cancel_button.connect('pressed', self, 'hide')


func initialize() -> bool:
	edited_scene_root = get_tree().get_edited_scene_root()
	if edited_scene_root == null:
		_show_alert(MSG_EMPTY_SCENE)
		return false

	var scene_filename := edited_scene_root.filename
	if not scene_filename:
		_show_alert(MSG_UNSAVED_SCENE)
		return false

	scene_tree.clear()

	var filtered_node_count := _add_node_to_scene_tree(edited_scene_root)

	if class_filters and filtered_node_count == 0:
		var filters_str := PoolStringArray(class_filters).join(" / ")
		_show_alert(MSG_NO_FILTERED_NODES_IN_SCENE % filters_str)
		return false

	return true


func _add_node_to_scene_tree(node : Node, parent : TreeItem = null) -> int:
	var tree_item := scene_tree.create_item(parent)

	var node_class := node.get_class()

	tree_item.set_icon(Columns.NAME, _editor_theme.get_icon(node_class))
	tree_item.set_text(Columns.NAME, node.name)

	tree_item.set_text(Columns.PATH, edited_scene_root.get_path_to(node))

	var disabled_font_color := _editor_theme.get_color("disabled_font_color")

	var filtered_node_count := 0
	if class_filters:
		var is_valid := false

		for filter in class_filters:
			if node.is_class(filter):
				is_valid = true
				filtered_node_count += 1
				break

		if not is_valid:
			tree_item.set_selectable(Columns.NAME, false)
			tree_item.set_icon_modulate(Columns.NAME, DISABLED_ICON_MODULATE)
			tree_item.set_custom_color(Columns.NAME, disabled_font_color)


	for child in node.get_children():
		if child.owner == edited_scene_root:
			filtered_node_count += _add_node_to_scene_tree(child, tree_item)

	return filtered_node_count


func _show_alert(message : String) -> void:
	alert_dialog.dialog_text = message
	alert_dialog.popup_centered()


func _update_theme(editor_theme : EditorTheme) -> void:
	_editor_theme = editor_theme


# Setters and Getters
func set_class_filters(filters : Array) -> void:
	class_filters = filters

	if class_filters != []:
		var filters_str := PoolStringArray(class_filters).join(" / ")
		window_title = WINDOW_TITLE_WITH_FILTER % filters_str
	else:
		window_title = WINDOW_TITLE_DEFAULT


# Signal Callbacks
func _on_node_selected() -> void:
	var selected_item := scene_tree.get_selected()

	if selected_item:
		var node_path := selected_item.get_text(Columns.PATH)
		var selected_node := edited_scene_root.get_node(node_path)

		emit_signal('node_selected', selected_node)

		hide()
