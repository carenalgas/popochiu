@tool
class_name PopochiuEditorConfig
extends RefCounted

enum Icons { COLLAPSED, EXPANDED }

# ASEPRITE IMPORTER --------------------------------------------------------------------------------
const ASEPRITE_IMPORTER_ENABLED = "popochiu/import/aseprite/enable_aseprite_importer"
const ASEPRITE_COMMAND_PATH = "popochiu/import/aseprite/command_path"
const ASEPRITE_REMOVE_JSON_FILE = "popochiu/import/aseprite/remove_json_file"

# GIZMOS -------------------------------------------------------------------------------------------
# --- Toolbar settings ---
const TOOLBAR_APPLY_COLORS_TO_BUTTONS = "popochiu/toolbar/apply_colors_to_toolbar_buttons"
const TOOLBAR_COMPACT_MODE = "popochiu/toolbar/compact_mode"
# --- General gizmo settings ---
const GIZMOS_FONT_SIZE = "popochiu/gizmos/font_size"
# --- Positional gizmo settings ---
const GIZMOS_HANDLER_SIZE = "popochiu/gizmos/positions/handler_size"
const GIZMOS_SHOW_POSITION = "popochiu/gizmos/positions/show_position"
const GIZMOS_SHOW_CONNECTORS = "popochiu/gizmos/positions/show_connectors"
const GIZMOS_SHOW_OUTLINE = "popochiu/gizmos/positions/show_handler_outline"
const GIZMOS_SHOW_NODE_NAME = "popochiu/gizmos/positions/show_node_name"
const GIZMOS_BASELINE_COLOR = "popochiu/gizmos/positions/baseline_color"
const GIZMOS_WALK_TO_POINT_COLOR = "popochiu/gizmos/positions/walk_to_point_color"
const GIZMOS_LOOK_AT_POINT_COLOR = "popochiu/gizmos/positions/look_at_point_color"
const GIZMOS_DIALOG_POS_COLOR = "popochiu/gizmos/positions/dialog_position_color"
const GIZMOS_MARKER_POS_COLOR = "popochiu/gizmos/positions/marker_position_color"
# --- Polygon gizmo settings ---
const GIZMOS_POLY_VERTEX_HANDLER_SIZE = "popochiu/gizmos/polygons/polygon_vertex_handler_size"
const GIZMOS_POLY_ENABLE_UNSELECTED_WA = "popochiu/gizmos/polygons/enable_unselected_walkable_area_polygons"
const GIZMOS_POLY_ENABLE_UNSELECTED_INT = "popochiu/gizmos/polygons/enable_unselected_interaction_polygons"
const GIZMOS_POLY_ENABLE_UNSELECTED_OBS = "popochiu/gizmos/polygons/enable_unselected_obstacle_polygons"
const GIZMOS_POLY_INTERACTION_COLOR = "popochiu/gizmos/polygons/interaction_polygons_color"
const GIZMOS_POLY_OBSTACLE_COLOR = "popochiu/gizmos/polygons/obstacle_polygons_color"
const GIZMOS_POLY_WALKABLE_AREA_COLOR = "popochiu/gizmos/polygons/walkable_area_polygons_color"
const GIZMOS_POLY_FILL_ALPHA = "popochiu/gizmos/polygons/polygons_fill_alpha"
const GIZMOS_POLY_PASSIVE_ALPHA_FACTOR = "popochiu/gizmos/polygons/passive_polygons_alpha_factor"

# Settings default values
static var defaults := {
	ASEPRITE_IMPORTER_ENABLED: false,
	ASEPRITE_COMMAND_PATH: _default_aseprite_command(),
	ASEPRITE_REMOVE_JSON_FILE: true,
	GIZMOS_FONT_SIZE: _default_font_size(),
	GIZMOS_BASELINE_COLOR: Color.ORANGE,
	GIZMOS_WALK_TO_POINT_COLOR: Color.GREEN,
	GIZMOS_LOOK_AT_POINT_COLOR: Color.RED,
	GIZMOS_DIALOG_POS_COLOR: Color.MAGENTA,
	GIZMOS_MARKER_POS_COLOR: Color.CYAN,
	TOOLBAR_APPLY_COLORS_TO_BUTTONS: true,
	TOOLBAR_COMPACT_MODE: false,
	GIZMOS_HANDLER_SIZE: 32,
	GIZMOS_SHOW_CONNECTORS: true,
	GIZMOS_SHOW_OUTLINE: true,
	GIZMOS_SHOW_NODE_NAME: true,
	GIZMOS_SHOW_POSITION: true,
	GIZMOS_POLY_ENABLE_UNSELECTED_WA: true,
	GIZMOS_POLY_ENABLE_UNSELECTED_INT: true,
	GIZMOS_POLY_ENABLE_UNSELECTED_OBS: true,
	GIZMOS_POLY_INTERACTION_COLOR: Color.YELLOW,
	GIZMOS_POLY_OBSTACLE_COLOR: Color.VIOLET,
	GIZMOS_POLY_WALKABLE_AREA_COLOR: Color.GREEN,
	GIZMOS_POLY_FILL_ALPHA: 0.15,
	GIZMOS_POLY_PASSIVE_ALPHA_FACTOR: 0.4,
	GIZMOS_POLY_VERTEX_HANDLER_SIZE: 6.0,
}

static var editor_settings: EditorSettings


#region Public #####################################################################################
static func initialize_editor_settings() -> void:
	editor_settings = EditorInterface.get_editor_settings()

	# Aseprite importer
	_initialize_editor_setting(ASEPRITE_IMPORTER_ENABLED, TYPE_BOOL)
	_initialize_editor_setting(ASEPRITE_COMMAND_PATH, TYPE_STRING)
	_initialize_editor_setting(ASEPRITE_REMOVE_JSON_FILE, TYPE_BOOL)
	# Toolbar
	_initialize_editor_setting(TOOLBAR_APPLY_COLORS_TO_BUTTONS, TYPE_BOOL)
	_initialize_editor_setting(TOOLBAR_COMPACT_MODE, TYPE_BOOL)
	# Gizmos
	# --- General gizmo settings ---
	_initialize_editor_setting(GIZMOS_FONT_SIZE, TYPE_INT, PROPERTY_HINT_RANGE, "4,64")
	# --- Positional gizmo settings ---
	_initialize_editor_setting(GIZMOS_HANDLER_SIZE, TYPE_INT, PROPERTY_HINT_RANGE, "4,64")
	_initialize_editor_setting(GIZMOS_SHOW_POSITION, TYPE_BOOL)
	_initialize_editor_setting(GIZMOS_SHOW_CONNECTORS, TYPE_BOOL)
	_initialize_editor_setting(GIZMOS_SHOW_OUTLINE, TYPE_BOOL)
	_initialize_editor_setting(GIZMOS_SHOW_NODE_NAME, TYPE_BOOL)
	_initialize_editor_setting(GIZMOS_BASELINE_COLOR, TYPE_COLOR)
	_initialize_editor_setting(GIZMOS_WALK_TO_POINT_COLOR, TYPE_COLOR)
	_initialize_editor_setting(GIZMOS_LOOK_AT_POINT_COLOR, TYPE_COLOR)
	_initialize_editor_setting(GIZMOS_DIALOG_POS_COLOR, TYPE_COLOR)
	_initialize_editor_setting(GIZMOS_MARKER_POS_COLOR, TYPE_COLOR)
	# --- Polygon gizmo settings ---
	_initialize_editor_setting(GIZMOS_POLY_ENABLE_UNSELECTED_WA, TYPE_BOOL)
	_initialize_editor_setting(GIZMOS_POLY_ENABLE_UNSELECTED_INT, TYPE_BOOL)
	_initialize_editor_setting(GIZMOS_POLY_ENABLE_UNSELECTED_OBS, TYPE_BOOL)
	_initialize_editor_setting(GIZMOS_POLY_INTERACTION_COLOR, TYPE_COLOR)
	_initialize_editor_setting(GIZMOS_POLY_OBSTACLE_COLOR, TYPE_COLOR)
	_initialize_editor_setting(GIZMOS_POLY_WALKABLE_AREA_COLOR, TYPE_COLOR)
	_initialize_editor_setting(GIZMOS_POLY_FILL_ALPHA, TYPE_FLOAT, PROPERTY_HINT_RANGE, "0.0,1.0,0.05")
	_initialize_editor_setting(GIZMOS_POLY_PASSIVE_ALPHA_FACTOR, TYPE_FLOAT, PROPERTY_HINT_RANGE, "0.0,1.0,0.05")
	_initialize_editor_setting(GIZMOS_POLY_VERTEX_HANDLER_SIZE, TYPE_INT, PROPERTY_HINT_RANGE, "4,64")


static func get_icon(icon: Icons) -> Texture2D:
	match icon:
		Icons.COLLAPSED:
			return EditorInterface.get_base_control().get_theme_icon(
				"GuiTreeArrowRight", "EditorIcons"
			)
		Icons.EXPANDED:
			return EditorInterface.get_base_control().get_theme_icon(
				"GuiTreeArrowDown", "EditorIcons"
			)
	
	return null


# ASEPRITE IMPORTER --------------------------------------------------------------------------------
static func aseprite_importer_enabled() -> bool:
	return get_editor_setting(ASEPRITE_IMPORTER_ENABLED)


static func get_command() -> String:
	return get_editor_setting(ASEPRITE_COMMAND_PATH)


static func should_remove_source_files() -> bool:
	return get_editor_setting(ASEPRITE_REMOVE_JSON_FILE)

#endregion


#region Private ####################################################################################
static func _default_aseprite_command() -> String:
	return 'aseprite'


static func _default_font_size() -> int:
	if Engine.is_editor_hint():
		return EditorInterface.get_editor_theme().default_font_size
	return 16


static func _initialize_editor_setting(
	key: String, type: int, hint: int = PROPERTY_HINT_NONE, hint_string : String = ""
) -> void:
	if editor_settings.has_setting(key): return
	
	editor_settings.set_setting(key, defaults[key])
	editor_settings.set_initial_value(key, defaults[key], false)
	editor_settings.add_property_info({
		"name": key,
		"type": type,
		"hint": hint,
		"hint_string": hint_string
	})


static func get_editor_setting(key: String) -> Variant:
	var e := editor_settings.get_setting(key)
	return e if e != null else defaults.get(key)


#endregion
