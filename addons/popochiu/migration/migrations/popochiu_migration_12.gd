@tool
class_name PopochiuMigration12
extends PopochiuMigration

const VERSION = 12
const DESCRIPTION = "Migrate Popochiu editor settings to the new toolbar and gizmos sections"
const STEPS = [
	"Migrate moved editor settings and remove deprecated keys",
]

const _DEPRECATED_GIZMOS_COLOR_TOOLBAR_BUTTONS = "popochiu/gizmos/apply_colors_to_toolbar_buttons"
const _DEPRECATED_GIZMOS_HANDLER_SIZE = "popochiu/gizmos/handler_size"
const _DEPRECATED_GIZMOS_SHOW_POSITION = "popochiu/gizmos/show_position"
const _DEPRECATED_GIZMOS_SHOW_CONNECTORS = "popochiu/gizmos/show_connectors"
const _DEPRECATED_GIZMOS_SHOW_OUTLINE = "popochiu/gizmos/show_handler_outline"
const _DEPRECATED_GIZMOS_SHOW_NODE_NAME = "popochiu/gizmos/show_node_name"
const _DEPRECATED_GIZMOS_BASELINE_COLOR = "popochiu/gizmos/baseline_color"
const _DEPRECATED_GIZMOS_WALK_TO_POINT_COLOR = "popochiu/gizmos/walk_to_point_color"
const _DEPRECATED_GIZMOS_LOOK_AT_POINT_COLOR = "popochiu/gizmos/look_at_point_color"
const _DEPRECATED_GIZMOS_DIALOG_POS_COLOR = "popochiu/gizmos/dialog_position_color"
const _DEPRECATED_GIZMOS_MARKER_POS_COLOR = "popochiu/gizmos/marker_position_color"
const _DEPRECATED_GIZMOS_ALWAYS_SHOW_WA = "popochiu/gizmos/always_show_walkable_areas"
const _DEPRECATED_GIZMOS_ALWAYS_SHOW_INT = "popochiu/gizmos/always_show_interaction_polygons"
const _DEPRECATED_GIZMOS_ALWAYS_SHOW_OBS = "popochiu/gizmos/always_show_obstacle_polygons"
const _DEPRECATED_GIZMOS_ALWAYS_SHOW_WA_POLYGONS = "popochiu/gizmos/polygons/always_show_walkable_areas_polygons"
const _DEPRECATED_GIZMOS_ALWAYS_SHOW_INT_POLYGONS = "popochiu/gizmos/polygons/always_show_interaction_polygons"
const _DEPRECATED_GIZMOS_ALWAYS_SHOW_OBS_POLYGONS = "popochiu/gizmos/polygons/always_show_obstacle_polygons"


#region Virtual ####################################################################################
func _is_migration_needed() -> bool:
	var editor_settings := EditorInterface.get_editor_settings()
	for mapping in _get_mappings():
		if editor_settings.has_setting(mapping.old_key):
			return true
	return false


func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			_migrate_editor_settings,
		]
	)


#endregion

#region Private ####################################################################################
func _migrate_editor_settings() -> Completion:
	var editor_settings := EditorInterface.get_editor_settings()
	var migrated_any := false

	for mapping in _get_mappings():
		if _migrate_editor_setting(editor_settings, mapping.old_key, mapping.new_key):
			migrated_any = true

	return Completion.DONE if migrated_any else Completion.IGNORED


func _migrate_editor_setting(editor_settings: EditorSettings, old_key: String, new_key: String) -> bool:
	if not editor_settings.has_setting(old_key):
		return false

	if not editor_settings.has_setting(new_key):
		editor_settings.set_setting(new_key, editor_settings.get_setting(old_key))

	# Remove deprecated key so old entries disappear from the Editor Settings UI.
	editor_settings.erase(old_key)
	return true


func _get_mappings() -> Array[Dictionary]:
	return [
		# Toolbar section
		{
			old_key = _DEPRECATED_GIZMOS_COLOR_TOOLBAR_BUTTONS,
			new_key = PopochiuEditorConfig.TOOLBAR_APPLY_COLORS_TO_BUTTONS,
		},
		# Positional gizmos section
		{
			old_key = _DEPRECATED_GIZMOS_HANDLER_SIZE,
			new_key = PopochiuEditorConfig.GIZMOS_HANDLER_SIZE,
		},
		{
			old_key = _DEPRECATED_GIZMOS_SHOW_POSITION,
			new_key = PopochiuEditorConfig.GIZMOS_SHOW_POSITION,
		},
		{
			old_key = _DEPRECATED_GIZMOS_SHOW_CONNECTORS,
			new_key = PopochiuEditorConfig.GIZMOS_SHOW_CONNECTORS,
		},
		{
			old_key = _DEPRECATED_GIZMOS_SHOW_OUTLINE,
			new_key = PopochiuEditorConfig.GIZMOS_SHOW_OUTLINE,
		},
		{
			old_key = _DEPRECATED_GIZMOS_SHOW_NODE_NAME,
			new_key = PopochiuEditorConfig.GIZMOS_SHOW_NODE_NAME,
		},
		{
			old_key = _DEPRECATED_GIZMOS_BASELINE_COLOR,
			new_key = PopochiuEditorConfig.GIZMOS_BASELINE_COLOR,
		},
		{
			old_key = _DEPRECATED_GIZMOS_WALK_TO_POINT_COLOR,
			new_key = PopochiuEditorConfig.GIZMOS_WALK_TO_POINT_COLOR,
		},
		{
			old_key = _DEPRECATED_GIZMOS_LOOK_AT_POINT_COLOR,
			new_key = PopochiuEditorConfig.GIZMOS_LOOK_AT_POINT_COLOR,
		},
		{
			old_key = _DEPRECATED_GIZMOS_DIALOG_POS_COLOR,
			new_key = PopochiuEditorConfig.GIZMOS_DIALOG_POS_COLOR,
		},
		{
			old_key = _DEPRECATED_GIZMOS_MARKER_POS_COLOR,
			new_key = PopochiuEditorConfig.GIZMOS_MARKER_POS_COLOR,
		},
		# Polygon visibility semantics/path changes
		{
			old_key = _DEPRECATED_GIZMOS_ALWAYS_SHOW_WA,
			new_key = PopochiuEditorConfig.GIZMOS_POLY_ENABLE_UNSELECTED_WA,
		},
		{
			old_key = _DEPRECATED_GIZMOS_ALWAYS_SHOW_INT,
			new_key = PopochiuEditorConfig.GIZMOS_POLY_ENABLE_UNSELECTED_INT,
		},
		{
			old_key = _DEPRECATED_GIZMOS_ALWAYS_SHOW_OBS,
			new_key = PopochiuEditorConfig.GIZMOS_POLY_ENABLE_UNSELECTED_OBS,
		},
		{
			old_key = _DEPRECATED_GIZMOS_ALWAYS_SHOW_WA_POLYGONS,
			new_key = PopochiuEditorConfig.GIZMOS_POLY_ENABLE_UNSELECTED_WA,
		},
		{
			old_key = _DEPRECATED_GIZMOS_ALWAYS_SHOW_INT_POLYGONS,
			new_key = PopochiuEditorConfig.GIZMOS_POLY_ENABLE_UNSELECTED_INT,
		},
		{
			old_key = _DEPRECATED_GIZMOS_ALWAYS_SHOW_OBS_POLYGONS,
			new_key = PopochiuEditorConfig.GIZMOS_POLY_ENABLE_UNSELECTED_OBS,
		},
	]


#endregion
