@tool
class_name PopochiuEditorHelper
extends Resource
# Utils class for Editor related things.

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
	CREATE_OBJECT_FOLDER + "create_walkable_area/create_walkable_area.tscn"
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
# ---- Utilities -------------------------------------------------------------------------------
const EMPTY_STRING := ""

static var signal_bus := PopochiuSignalBus.new()
static var ei := EditorInterface
static var undo_redo: EditorUndoRedoManager = null
static var dock: Panel = null

static var _room_scene_path_template := PopochiuResources.ROOMS_PATH.path_join("%s/room_%s.tscn")
static var _setup_dialog_instance: ConfirmationDialog = null

# Godot 4.x reserved names from:
# - Language keywords: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#keywords
# - Global scope: https://docs.godotengine.org/en/stable/classes/class_%40globalscope.html
const GDSCRIPT_RESERVED_NAMES: Array[String] = [
	# Language Keywords
	"if", "elif", "else", "for", "while", "match", "when",
	"break", "continue", "pass", "return",
	"class", "class_name", "extends", "is", "in", "as",
	"self", "super", "signal", "func", "static",
	"const", "enum", "var", "breakpoint", "preload",
	"await", "yield", "assert", "void",
	
	# Global Constants
	"PI", "TAU", "INF", "NAN",
	
	# Literals
	"null", "true", "false",
	
	# Basic Built-in Types
	"bool", "int", "float", "String", "StringName", "NodePath",
	
	# Vector/Matrix Types
	"Vector2", "Vector2i", "Rect2", "Rect2i",
	"Vector3", "Vector3i", "Vector4", "Vector4i",
	"Transform2D", "Transform3D", "Projection",
	"Plane", "Quaternion", "AABB", "Basis",
	
	# Engine Types
	"Color", "RID", "Object",
	
	# Container Types
	"Array", "Dictionary", "Signal", "Callable",
	
	# Packed Array Types
	"PackedByteArray", "PackedInt32Array", "PackedInt64Array",
	"PackedFloat32Array", "PackedFloat64Array", "PackedStringArray",
	"PackedVector2Array", "PackedVector3Array", "PackedVector4Array",
	"PackedColorArray",

	# Global Enum Types (@GlobalScope)
	"Side", "Corner", "Orientation", "ClockDirection",
	"HorizontalAlignment", "VerticalAlignment", "InlineAlignment",
	"EulerOrder", "Key", "KeyModifierMask", "KeyLocation",
	"MouseButton", "MouseButtonMask",
	"JoyButton", "JoyAxis", "MIDIMessage",
	"Error", "PropertyHint", "PropertyUsageFlags",
	"MethodFlags", "Variant",
]


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
		func() -> void:
			if content.on_confirmed:
				content.on_confirmed.call()

			dialog.queue_free()
	)
	dialog.canceled.connect(
		func() -> void:
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
		func() -> void:
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


static func show_setup() -> void:
	if is_instance_valid(_setup_dialog_instance):
		await show_dialog(_setup_dialog_instance)

		return

	var dialog := ConfirmationDialog.new()
	var content := SETUP_SCENE.instantiate()

	dialog.title = "Setup your game"
	dialog.ok_button_text = "Create"
	dialog.dialog_hide_on_ok = false
	dialog.confirmed.connect(
		func() -> void:
			await content.on_confirm()
			# The assignment must be done here, since doing it when the ConfirmationDialog is
			# instantiated causes the engine to crash after trying to create Popochiu objects following
			# the installation process.
			_setup_dialog_instance = dialog
			_setup_dialog_instance.hide()
	)
	dialog.close_requested.connect(content.on_close)
	dialog.about_to_popup.connect(content.on_about_to_popup)

	dialog.add_child(content)
	dock.add_child.call_deferred(dialog)
	await dialog.ready

	content.define_content()
	content.size_calculated.connect(
		func() -> void:
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
static func is_popochiu_clickable(node: Node) -> bool:
	return node is PopochiuCharacter \
	or node is PopochiuProp \
	or node is PopochiuHotspot


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


static func is_popochiu_obj_polygon(node: Node) -> bool:
	return node.is_in_group(POPOCHIU_OBJECT_POLYGON_GROUP)


static func is_popochiu_obstacle_polygon(node: Node) -> bool:
	return node is NavigationObstacle2D


# Context-checking functions
static func is_editing_room() -> bool:
	# If the open scene in the editor is a PopochiuRoom, return true
	return is_room(ei.get_edited_scene_root())


static func is_editing_character() -> bool:
	# If the open scene in the editor is a PopochiuRoom, return true
	return is_character(ei.get_edited_scene_root())


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
		return children # empty array
	children.push_back(node)
	for child in node.get_children():
		children = get_all_children(child, children)
	return children


# Overrides the font [param font_name] in [param node] by the theme [Font] identified by
# [param editor_font_name].
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


# Helper function to recursively remove all folders and files inside [param folder_path].
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


# Helper function to get the absolute directory paths for all folders under [param folder_path].
static func get_absolute_directory_paths_at(folder_path: String) -> Array:
	var dir_array: PackedStringArray = []

	if DirAccess.dir_exists_absolute(folder_path):
		for folder in DirAccess.get_directories_at(folder_path):
			dir_array.append(folder_path.path_join(folder))

	return Array(dir_array)


# Helper function to get the absolute file paths for all files under [param folder_path].
static func get_absolute_file_paths_at(folder_path: String) -> PackedStringArray:
	var file_array: PackedStringArray = []

	if DirAccess.dir_exists_absolute(folder_path):
		for file in DirAccess.get_files_at(folder_path):
			file_array.append(folder_path.path_join(file))

	return file_array


# Returns an array of [PopochiuRoom] (instances) for all the rooms in the project.
static func get_rooms() -> Array[PopochiuRoom]:
	var rooms: Array[PopochiuRoom] = []
	rooms.assign(PopochiuResources.get_section_keys("rooms").map(
		func(room_name: String) -> PopochiuRoom:
			var scene_path := _room_scene_path_template.replace("%s", room_name.to_snake_case())
			return (load(scene_path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	))
	return rooms


# Check if a string represents a valid path (optionally including a file name).
static func is_valid_godot_path(path: String, expect_file: bool = false) -> bool:
	if path.is_empty():
		return false

	# Must start with a supported prefix
	if not (path.begins_with("res://") or path.begins_with("user://")):
		PopochiuUtils.print_warning("Path must start with 'res://' or 'user://'")
		return false

	# Optional: validate the filename part doesn't contain illegal chars
	if expect_file:
		var filename: String = path.get_file()
		if not filename.is_valid_filename():
			PopochiuUtils.print_warning("Filename contains invalid characters.")
			return false
		# Check existence
		if not FileAccess.file_exists(path):
			PopochiuUtils.print_warning("File does not exist.")
			return false
		
		return true

	if not DirAccess.dir_exists_absolute(path):
		PopochiuUtils.print_warning("Directory does not exist.")
		return false
	
	return true


# Check if a string represents a valid GDScript function name.
static func is_valid_function_name(name: String, check_snake_case: bool = false) -> bool:
	var _valid_name_regex: RegEx = RegEx.new()
	_valid_name_regex.compile("^[a-zA-Z_][a-zA-Z0-9_]*$")

	# 1. Cannot be empty
	if name.is_empty():
		PopochiuUtils.print_warning("Function name cannot be empty.")
		return false

	# 2. Must match valid identifier pattern
	if not _valid_name_regex.search(name):
		PopochiuUtils.print_warning("Function name contains invalid characters.")
		return false

	# 3. Cannot be a reserved name
	if name in GDSCRIPT_RESERVED_NAMES:
		PopochiuUtils.print_warning(
			"Function name cannot be a reserved keyword or a global scope symbol."
		)
		return false

	# 4. Obey snake case convention
	if check_snake_case and name != name.to_snake_case():
		PopochiuUtils.print_warning("Function name is not snake case.")
		return false
	
	return true


#endregion #########################################################################################
