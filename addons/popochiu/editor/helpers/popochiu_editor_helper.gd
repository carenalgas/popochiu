@tool
class_name PopochiuEditorHelper
extends Resource
## Utils class for Editor related things.

# ---- Strings, paths, scenes, and other values ----------------------------------------------------
const POPUPS_FOLDER = "res://addons/popochiu/editor/popups/"
const CREATE_OBJECT_FOLDER = "res://addons/popochiu/editor/popups/create_object/"
const CREATE_ROOM = preload(CREATE_OBJECT_FOLDER + "create_room/create_room.tscn")
const CREATE_CHARACTER = preload(CREATE_OBJECT_FOLDER + "create_character/create_character.tscn")
const CREATE_INVENTORY_ITEM = preload(
	CREATE_OBJECT_FOLDER + "create_inventory_item/create_inventory_item.tscn"
)
const CREATE_DIALOG = preload(CREATE_OBJECT_FOLDER + "create_dialog/create_dialog.tscn")
const CREATE_PROP = preload(CREATE_OBJECT_FOLDER + "create_prop/create_prop.tscn")
const CREATE_HOTSPOT = preload(CREATE_OBJECT_FOLDER + "create_hotspot/create_hotspot.tscn")
const CREATE_WALKABLE_AREA = preload(
	CREATE_OBJECT_FOLDER + 	"create_walkable_area/create_walkable_area.tscn"
)
const CREATE_REGION = preload(CREATE_OBJECT_FOLDER + "create_region/create_region.tscn")
const CREATE_MARKER = preload(CREATE_OBJECT_FOLDER + "create_marker/create_marker.tscn")
const DELETE_CONFIRMATION_SCENE = preload(
	POPUPS_FOLDER + "delete_confirmation/delete_confirmation.tscn"
)
const PROGRESS_DIALOG_SCENE = preload(POPUPS_FOLDER + "progress/progress.tscn")
const SETUP_SCENE = preload("res://addons/popochiu/editor/popups/setup/setup.tscn")
# ---- Identifiers ---------------------------------------------------------------------------------
const POPOCHIU_OBJECT_POLYGON_GROUP = "popochiu_object_polygon"
# ---- Classes -------------------------------------------------------------------------------------
const PopochiuSignalBus = preload("res://addons/popochiu/editor/helpers/popochiu_signal_bus.gd")
const DeleteConfirmation = preload(POPUPS_FOLDER + "delete_confirmation/delete_confirmation.gd")
const Progress = preload(POPUPS_FOLDER + "progress/progress.gd")
const CreateObject = preload(CREATE_OBJECT_FOLDER + "create_object.gd")

static var signal_bus := PopochiuSignalBus.new()
static var ei := EditorInterface
static var undo_redo: EditorUndoRedoManager = null
static var dock: Panel = null


#region Public #####################################################################################
static func select_node(node: Node) -> void:
	ei.get_selection().clear()
	ei.get_selection().add_node(node)


static func show_popup(popup_name: String) -> void:
	PopochiuUtils.print_normal(popup_name)


static func add_resource_to_popochiu(target: String, resource: Resource) -> int:
	return PopochiuResources.set_data_value(target, resource.script_name, resource.resource_path)


static func show_delete_confirmation(
	content: DeleteConfirmation, min_size := Vector2i(640, 160)
) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = content.title
	
	dialog.confirmed.connect(
		func () -> void:
			if content.on_confirmed:
				content.on_confirmed.call()
			
			dialog.queue_free()
	)
	dialog.canceled.connect(
		func () -> void:
			if content.on_canceled:
				content.on_canceled.call()
			
			dialog.queue_free()
	)
	dialog.about_to_popup.connect(content.on_about_to_popup)
	dialog.add_child(content)
	
	await show_dialog(dialog, min_size)


static func show_progress(min_size := Vector2i(640, 80)) -> Progress:
	var dialog := AcceptDialog.new()
	var content: Progress = PROGRESS_DIALOG_SCENE.instantiate()
	
	dialog.borderless = true
	dialog.add_child(content)
	dialog.get_ok_button().hide()
	await show_dialog(dialog, min_size)
	
	return content


static func show_creation_popup(scene: PackedScene, min_size := Vector2i(640, 180)) -> void:
	var content: CreateObject = scene.instantiate()
	var dialog := ConfirmationDialog.new()
	
	content.content_changed.connect(
		func () -> void:
			content.custom_minimum_size = content.get_child(0).size
			content.size = content.get_child(0).size
			
			dialog.reset_size()
			dialog.move_to_center()
	)
	dialog.confirmed.connect(content.create)
	dialog.canceled.connect(dialog.queue_free)
	dialog.about_to_popup.connect(content.on_about_to_popup)
	dialog.add_child(content)
	await show_dialog(dialog, min_size)
	
	dialog.register_text_enter(content.input)


static func show_setup(is_welcome := false) -> void:
	var dialog := ConfirmationDialog.new()
	var content := SETUP_SCENE.instantiate()
	
	dialog.title = "Setup"
	dialog.confirmed.connect(content.on_close)
	dialog.close_requested.connect(content.on_close)
	dialog.about_to_popup.connect(content.on_about_to_popup)
	
	dialog.add_child(content)
	dock.add_child.call_deferred(dialog)
	await dialog.ready
	
	content.define_content(is_welcome)
	content.size_calculated.connect(
		func () -> void:
			dialog.reset_size()
			dialog.move_to_center()
	)
	
	await show_dialog(dialog, content.custom_minimum_size)


static func show_dialog(dialog: Window, min_size := Vector2i.ZERO) -> void:
	if not dialog.is_inside_tree():
		dock.add_child.call_deferred(dialog)
		await dialog.ready
	
	dialog.popup_centered(min_size * EditorInterface.get_editor_scale())



# Type-checking functions
static func is_popochiu_object(node: Node) -> bool:
	return node is PopochiuRoom \
	or is_popochiu_room_object(node)


static func is_popochiu_room_object(node: Node) -> bool:
	return node is PopochiuCharacter \
	or node is PopochiuProp \
	or node is PopochiuHotspot \
	or node is PopochiuWalkableArea \
	or node is PopochiuRegion


static func is_room(node: Node) -> bool:
	return node is PopochiuRoom


static func is_character(node: Node) -> bool:
	return node is PopochiuCharacter


static func is_prop(node: Node) -> bool:
	return node is PopochiuProp


static func is_hotspot(node: Node) -> bool:
	return node is PopochiuHotspot


static func is_walkable_area(node: Node) -> bool:
	return node is PopochiuWalkableArea


static func is_region(node: Node) -> bool:
	return node is PopochiuRegion


static func is_popochiu_obj_polygon(node: Node):
	return node.is_in_group(POPOCHIU_OBJECT_POLYGON_GROUP)


# Context-checking functions
static func is_editing_room() -> bool:
	# If the open scene in the editor is a PopochiuRoom, return true
	return is_room(ei.get_edited_scene_root())


# Quick-access functions
static func get_first_child_by_group(node: Node, group: StringName) -> Node:
	for n in node.get_children():
		if n.is_in_group(group):
			return n
	return null


static func get_all_children(node, children := []) -> Array:
	if node == null:
		return []
	children.push_back(node)
	for child in node.get_children():
		children = get_all_children(child, children)
	return children

## Overrides the font [param font_name] in [param node] by the theme [Font] identified by
## [param editor_font_name].
static func override_font(node: Control, font_name: String, editor_font_name: String) -> void:
	node.add_theme_font_override(font_name, node.get_theme_font(editor_font_name, "EditorFonts"))


#endregion
