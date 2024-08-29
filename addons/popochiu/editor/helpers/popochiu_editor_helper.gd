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
const MIGRATIONS_PANEL_SCENE = preload(
	"res://addons/popochiu/editor/popups/migrations_panel/migrations_panel.tscn"
)
# ---- Classes -------------------------------------------------------------------------------------
const PopochiuSignalBus = preload("res://addons/popochiu/editor/helpers/popochiu_signal_bus.gd")
const DeleteConfirmation = preload(POPUPS_FOLDER + "delete_confirmation/delete_confirmation.gd")
const Progress = preload(POPUPS_FOLDER + "progress/progress.gd")
const CreateObject = preload(CREATE_OBJECT_FOLDER + "create_object.gd")
const MigrationsPanel = preload(
	"res://addons/popochiu/editor/popups/migrations_panel/migrations_panel.gd"
)

static var signal_bus := PopochiuSignalBus.new()
static var ei := EditorInterface
static var undo_redo: EditorUndoRedoManager = null
static var dock: Panel = null

static var _room_scene_path_template := PopochiuResources.ROOMS_PATH.path_join("%s/room_%s.tscn")


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


static func show_migrations(
	content: MigrationsPanel, min_size := Vector2i(640, 640)
) -> AcceptDialog:
	var dialog := AcceptDialog.new()
	dialog.title = "Migration Tool"
	content.anchors_preset = Control.PRESET_FULL_RECT
	dialog.add_child(content)
	await show_dialog(dialog, min_size)
	
	return dialog


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


static func is_marker(node: Node) -> bool:
	return node is Marker2D


static func is_popochiu_obj_polygon(node: Node):
	return node.is_in_group(POPOCHIU_OBJECT_POLYGON_GROUP)


# Context-checking functions
static func is_editing_room() -> bool:
	# If the open scene in the editor is a PopochiuRoom, return true
	return is_room(ei.get_edited_scene_root())


# Quick-access functions
static func get_first_child_by_group(node: Node, group: StringName) -> Node:
	if (node == null):
		return null
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


static func frame_processed() -> void:
	await EditorInterface.get_base_control().get_tree().process_frame


static func secs_passed(secs := 1.0) -> void:
	await EditorInterface.get_base_control().get_tree().create_timer(secs).timeout


static func filesystem_scanned() -> void:
	EditorInterface.get_resource_filesystem().scan.call_deferred()
	await EditorInterface.get_resource_filesystem().filesystem_changed


static func pack_scene(node: Node, path := "") -> int:
	var packed_scene := PackedScene.new()
	packed_scene.pack(node)
	
	if path.is_empty():
		path = node.scene_file_path
	
	return ResourceSaver.save(packed_scene, path)


## Helper function to recursively remove all folders and files inside [param folder_path].
static func remove_recursive(folder_path: String) -> bool:
	if DirAccess.dir_exists_absolute(folder_path):
		# Delete subfolders and their contents recursively in folder_path
		for subfolder_path: String in get_absolute_directory_paths_at(folder_path):
			remove_recursive(subfolder_path)
		
		# Delete all files in folder_path
		for file_path: String in get_absolute_file_paths_at(folder_path):
			if DirAccess.remove_absolute(file_path) != OK:
				return false
		
		# Once all files are deleted in folder_path, remove folder_path
		if DirAccess.remove_absolute(folder_path) != OK:
			return false
	return true


## Helper function to get the absolute directory paths for all folders under [param folder_path].
static func get_absolute_directory_paths_at(folder_path: String) -> Array:
	var dir_array : PackedStringArray = []
	
	if DirAccess.dir_exists_absolute(folder_path):
		for folder in DirAccess.get_directories_at(folder_path):
			dir_array.append(folder_path.path_join(folder))
	
	return Array(dir_array)


## Helper function to get the absolute file paths for all files under [param folder_path].
static func get_absolute_file_paths_at(folder_path: String) -> PackedStringArray:
	var file_array : PackedStringArray = []
	
	if DirAccess.dir_exists_absolute(folder_path):
		for file in DirAccess.get_files_at(folder_path): 
			file_array.append(folder_path.path_join(file))
	
	return file_array


## Returns an array of [PopochiuRoom] (instances) for all the rooms in the project.
static func get_rooms() -> Array[PopochiuRoom]:
	var rooms: Array[PopochiuRoom] = []
	rooms.assign(PopochiuResources.get_section_keys("rooms").map(
		func (room_name: String) -> PopochiuRoom:
			var scene_path := _room_scene_path_template.replace("%s", room_name.to_snake_case())
			return (load(scene_path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	))
	return rooms


#endregion
