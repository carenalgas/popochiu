@tool
extends HBoxContainer
## Used to show new buttons in the EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU (the top bar in the
## 2D editor) to toggle gizmo visibility for PopochiuClickable objects.

const PASSIVE_SCOPE_SELECTED_ICON: Texture2D = preload(
	"res://addons/popochiu/icons/btn_psv_gz_scope_selected.svg"
)
const PASSIVE_SCOPE_ROOM_ICON: Texture2D = preload(
	"res://addons/popochiu/icons/btn_psv_gz_scope_room.svg"
)

var _active_popochiu_object: Node = null
var _shown_helpers := []
var _passive_scope: int = PopochiuGizmoPlugin.PASSIVE_SCOPE_SELECTED

@onready var btn_markers: Button = %BtnMarkers
@onready var btn_baseline: Button = %BtnBaseline
@onready var btn_walk_to_point: Button = %BtnWalkToPoint
@onready var btn_look_at_point: Button = %BtnLookAtPoint
@onready var btn_dialog_pos: Button = %BtnDialogPos
@onready var btn_interaction_polygon: Button = %BtnInteractionPolygon
@onready var btn_obstacle_polygon: Button = %BtnObstaclePolygon
@onready var btn_passive_scope: Button = %BtnPassiveScope
@onready var btn_walkable_area_polygon: Button = %BtnWalkableAreaPolygon
@onready var label_view: Label = %LabelView
@onready var label_edit: Label = %LabelEdit


#region Godot ######################################################################################
func _ready() -> void:
	# In Godot 4.6, controls added to CONTAINER_CANVAS_EDITOR_MENU are wrapped
	# inside a contextual PanelContainer that paints a background stylebox.
	# We clear that style so this toolbar group stays visually transparent.
	_set_context_toolbar_transparent()

	# Gizmos are always visible at editor load, so we'll set the buttons down
	# to sync the status (hardcoded, not very good but enough for now)
	_reset_buttons_state()

	# Connect to child signals
	btn_markers.pressed.connect(_toggle_markers_visibility)
	btn_baseline.pressed.connect(_toggle_baseline_visibility)
	btn_walk_to_point.pressed.connect(_toggle_walk_to_point_visibility)
	btn_look_at_point.pressed.connect(_toggle_look_at_point_visibility)
	btn_dialog_pos.pressed.connect(_toggle_dialog_pos_visibility)
	btn_interaction_polygon.pressed.connect(_toggle_interaction_polygon_visibility)
	btn_obstacle_polygon.pressed.connect(_toggle_obstacle_polygon_visibility)
	btn_passive_scope.pressed.connect(_toggle_passive_scope)
	btn_walkable_area_polygon.pressed.connect(_toggle_walkable_area_polygon_visibility)

	# Connect to global signals
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	EditorInterface.get_editor_settings().settings_changed.connect(_on_gizmo_settings_changed)
	_sync_polygon_toolbar_state()

	_set_toolbar_buttons_color()
	hide()


func _set_context_toolbar_transparent() -> void:
	var toolbar_hbox := get_parent() as Control
	if toolbar_hbox == null:
		return

	var toolbar_panel := toolbar_hbox.get_parent() as PanelContainer
	if toolbar_panel == null:
		return

	toolbar_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())


func _sync_polygon_toolbar_state() -> void:
	PopochiuEditorHelper.signal_bus.gizmo_visibility_changed.emit(
		PopochiuGizmoPlugin.INTERACTION_POLYGON,
		btn_interaction_polygon.button_pressed
	)
	PopochiuEditorHelper.signal_bus.gizmo_visibility_changed.emit(
		PopochiuGizmoPlugin.OBSTACLE_POLYGON,
		btn_obstacle_polygon.button_pressed
	)
	PopochiuEditorHelper.signal_bus.gizmo_visibility_changed.emit(
		PopochiuGizmoPlugin.WALKABLE_AREA_POLYGON,
		btn_walkable_area_polygon.button_pressed
	)
	_update_passive_scope_button_visuals()
	PopochiuEditorHelper.signal_bus.gizmo_passive_scope_changed.emit(_passive_scope)
	PopochiuEditorHelper.signal_bus.gizmo_walkable_passive_visibility_changed.emit(
		btn_walkable_area_polygon.button_pressed
	)
#endregion

#region Signals ####################################################################################
func _toggle_markers_visibility() -> void:
	PopochiuEditorHelper.signal_bus.gizmo_visibility_changed.emit(
		PopochiuGizmoPlugin.MARKER_POS,
		btn_markers.button_pressed
	)


func _toggle_baseline_visibility() -> void:
	PopochiuEditorHelper.signal_bus.gizmo_visibility_changed.emit(
		PopochiuGizmoPlugin.BASELINE,
		btn_baseline.button_pressed
	)


func _toggle_walk_to_point_visibility() -> void:
	PopochiuEditorHelper.signal_bus.gizmo_visibility_changed.emit(
		PopochiuGizmoPlugin.WALK_TO_POINT,
		btn_walk_to_point.button_pressed
	)


func _toggle_look_at_point_visibility() -> void:
	PopochiuEditorHelper.signal_bus.gizmo_visibility_changed.emit(
		PopochiuGizmoPlugin.LOOK_AT_POINT,
		btn_look_at_point.button_pressed
	)


func _toggle_dialog_pos_visibility() -> void:
	PopochiuEditorHelper.signal_bus.gizmo_visibility_changed.emit(
		PopochiuGizmoPlugin.DIALOG_POS,
		btn_dialog_pos.button_pressed
	)


# Toggle the interaction polygon gizmo visibility via the signal bus.
# The polygon gizmo draws on the viewport overlay; no child node selection needed.
# We also toggle WALKABLE_AREA_POLYGON because for PopochiuWalkableArea objects
# the perimeter polygon is categorised as WALKABLE_AREA internally.
func _toggle_interaction_polygon_visibility() -> void:
	PopochiuEditorHelper.signal_bus.gizmo_visibility_changed.emit(
		PopochiuGizmoPlugin.INTERACTION_POLYGON,
		btn_interaction_polygon.button_pressed
	)


# Toggle the obstacle polygon gizmo visibility via the signal bus.
func _toggle_obstacle_polygon_visibility() -> void:
	PopochiuEditorHelper.signal_bus.gizmo_visibility_changed.emit(
		PopochiuGizmoPlugin.OBSTACLE_POLYGON,
		btn_obstacle_polygon.button_pressed
	)


# Toggle passive scope with a single action button. The icon always shows
# the next action (switch to selected-object scope or whole-room scope).
func _toggle_passive_scope() -> void:
	if _passive_scope == PopochiuGizmoPlugin.PASSIVE_SCOPE_SELECTED:
		_passive_scope = PopochiuGizmoPlugin.PASSIVE_SCOPE_ROOM
	else:
		_passive_scope = PopochiuGizmoPlugin.PASSIVE_SCOPE_SELECTED

	_update_passive_scope_button_visuals()
	PopochiuEditorHelper.signal_bus.gizmo_passive_scope_changed.emit(_passive_scope)


# Toggle the walkable area polygon visibility via the signal bus. This is
# a separate setting from the main visibility settings, since it affects the
# visibility of passive gizmos that are not directly tied to the selected object.
func _toggle_walkable_area_polygon_visibility() -> void:
	PopochiuEditorHelper.signal_bus.gizmo_visibility_changed.emit(
		PopochiuGizmoPlugin.WALKABLE_AREA_POLYGON,
		btn_walkable_area_polygon.button_pressed
	)
	PopochiuEditorHelper.signal_bus.gizmo_walkable_passive_visibility_changed.emit(
		btn_walkable_area_polygon.button_pressed
	)


# When gizmo-related editor settings change, we update the toolbar buttons colors
func _on_gizmo_settings_changed() -> void:
	_set_toolbar_buttons_color()
	_set_buttons_visibility()


# Refreshes the toolbar after the editor selection changes.
func _on_selection_changed() -> void:
	# If we are editing the popochiu_canvas_editor_menu scene in
	# Godot, the edited scene root is the menu itself.
	# In that case, don't hide it!
	if EditorInterface.get_edited_scene_root() == self:
		return

	# Make sure this function works only if the user is editing a
	# supported scene.
	if not PopochiuEditorHelper.is_popochiu_object(
		EditorInterface.get_edited_scene_root()
	):
		hide()
		return

	# If we have no selection in the tree (the user clicked on an
	# empty area or pressed ESC), we hide the toolbar.
	if EditorInterface.get_selection().get_selected_nodes().is_empty():
		if _active_popochiu_object != null:
			# This "if" solves "!p_node->is_inside_tree()" internal Godot error
			if EditorInterface.get_edited_scene_root() == _active_popochiu_object:
				EditorInterface.get_selection().add_node.call_deferred(_active_popochiu_object)
		# Reset the clickable reference and hide the toolbar
		# (restart from a blank state)
		_active_popochiu_object = null
		hide()
		return

	# Identify which PopochiuClickable or room object we are working on
	if EditorInterface.get_selection().get_selected_nodes().size() >= 1:
		var selected_node = EditorInterface.get_selection().get_selected_nodes()[0]
		if PopochiuEditorHelper.is_popochiu_room_object(selected_node):
			_active_popochiu_object = selected_node
		elif selected_node is PopochiuRoom:
			# The room root itself is selected: no specific object
			# TODO: remove this branch?
			_active_popochiu_object = null
		else:
			_active_popochiu_object = null

	# Always reset the button visibility depending on the state of the internal variables
	_set_buttons_visibility()
	# Update the interaction polygon button color depending on the selected object
	# (walkable areas have a different color from clickables and characters)
	_set_interaction_polygon_button_color()


# Sets all the buttons color so that they are the same as the gizmos
# or make them theme-standard if the user so prefers (see editor settings)
func _set_toolbar_buttons_color() -> void:
	if not PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.TOOLBAR_APPLY_COLORS_TO_BUTTONS):
		# Reset button colors
		_reset_toolbar_button_color(btn_markers)
		_reset_toolbar_button_color(btn_baseline)
		_reset_toolbar_button_color(btn_walk_to_point)
		_reset_toolbar_button_color(btn_look_at_point)
		_reset_toolbar_button_color(btn_dialog_pos)
		_reset_toolbar_button_color(btn_interaction_polygon)
		_reset_toolbar_button_color(btn_obstacle_polygon)
		_reset_toolbar_button_color(btn_walkable_area_polygon)
		# Done
		return

	_set_toolbar_button_color(
		btn_markers,
		PopochiuEditorConfig.get_editor_setting(
			PopochiuEditorConfig.GIZMOS_MARKER_POS_COLOR)
	)
	_set_toolbar_button_color(
		btn_baseline,
		PopochiuEditorConfig.get_editor_setting(
			PopochiuEditorConfig.GIZMOS_BASELINE_COLOR)
	)
	_set_toolbar_button_color(
		btn_walk_to_point,
		PopochiuEditorConfig.get_editor_setting(
			PopochiuEditorConfig.GIZMOS_WALK_TO_POINT_COLOR)
	)
	_set_toolbar_button_color(
		btn_look_at_point,
		PopochiuEditorConfig.get_editor_setting(
			PopochiuEditorConfig.GIZMOS_LOOK_AT_POINT_COLOR)
	)
	_set_toolbar_button_color(
		btn_dialog_pos,
		PopochiuEditorConfig.get_editor_setting(
			PopochiuEditorConfig.GIZMOS_DIALOG_POS_COLOR)
	)
	# Treated as a special case because walkable areas polygons have a different color
	# from clickables and characters
	_set_interaction_polygon_button_color()
	_set_toolbar_button_color(
		btn_obstacle_polygon,
		PopochiuEditorConfig.get_editor_setting(
			PopochiuEditorConfig.GIZMOS_POLY_OBSTACLE_COLOR)
	)
	_set_toolbar_button_color(
		btn_walkable_area_polygon,
		PopochiuEditorConfig.get_editor_setting(
			PopochiuEditorConfig.GIZMOS_POLY_WALKABLE_AREA_COLOR)
	)



# Sets the color of the interaction polygon button depending on the selected
# node (walkable areas have a different color from clickables and characters).
func _set_interaction_polygon_button_color() -> void:
	if _active_popochiu_object is PopochiuWalkableArea:
		_set_toolbar_button_color(
			btn_interaction_polygon,
			PopochiuEditorConfig.get_editor_setting(
				PopochiuEditorConfig.GIZMOS_POLY_WALKABLE_AREA_COLOR)
		)
	else:
		_set_toolbar_button_color(
			btn_interaction_polygon,
			PopochiuEditorConfig.get_editor_setting(
				PopochiuEditorConfig.GIZMOS_POLY_INTERACTION_COLOR)
		)


# Internal helper to reduce code duplication
func _set_toolbar_button_color(btn, color) -> void:
	btn.add_theme_color_override("icon_normal_color", color)
	btn.add_theme_color_override("icon_hover_color", color.lightened(1.0))
	btn.add_theme_color_override("icon_focused_color", color.lightened(1.0))
	btn.add_theme_color_override("icon_pressed_color", color.darkened(0.2))
	btn.add_theme_color_override("icon_hover_pressed_color", color.lightened(1.0))


# Internal helper to reduce code duplication
func _reset_toolbar_button_color(btn) -> void:
	btn.remove_theme_color_override("icon_normal_color")
	btn.remove_theme_color_override("icon_hover_color")
	btn.remove_theme_color_override("icon_focused_color")
	btn.remove_theme_color_override("icon_pressed_color")
	btn.remove_theme_color_override("icon_hover_pressed_color")


# Set the visibility of the buttons depending on the current editing context and
# the type of the selected object. The buttons are shown only if they are relevant
# for the current selection.
func _set_buttons_visibility() -> void:
	# Let's assume the buttons are all hidden...
	hide()
	label_view.hide()
	label_edit.hide()
	btn_markers.hide()
	btn_baseline.hide()
	btn_walk_to_point.hide()
	btn_look_at_point.hide()
	btn_dialog_pos.hide()
	btn_interaction_polygon.hide()
	btn_obstacle_polygon.hide()
	btn_passive_scope.hide()
	btn_walkable_area_polygon.hide()

	# If we are not in a room and we are not editing a Popochiu object, nothing to do
	if not (
		PopochiuEditorHelper.is_popochiu_room_object(_active_popochiu_object)
		or PopochiuEditorHelper.is_editing_room()
		or PopochiuEditorHelper.is_editing_character()
	):
		return

	# Now we know we have to show the toolbar
	show()

	# Every Popochiu clickable shows the polygon toggle buttons when selected
	# in a room scene. Same when the scene is a character scene.
	if (
		(
			PopochiuEditorHelper.is_editing_room()
			and PopochiuEditorHelper.is_popochiu_room_object(_active_popochiu_object)
		)
		or PopochiuEditorHelper.is_editing_character()
	):
		btn_interaction_polygon.show()

	# Exception: in a room scene with a character selected,
	# we don't show the interaction polygon button.
	if (
		PopochiuEditorHelper.is_editing_room()
		and PopochiuEditorHelper.is_character(_active_popochiu_object)
	):
		btn_interaction_polygon.hide()

	# If we are in a room scene...
	if PopochiuEditorHelper.is_editing_room():
		# We always show the markers button
		btn_markers.show()
		# Scope control appears only if interaction or obstacle overlays are enabled
		if (
			PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_POLY_ENABLE_UNSELECTED_INT)
			or PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_POLY_ENABLE_UNSELECTED_OBS)
		):
			btn_passive_scope.show()
		# Walkable-area overlay toggle appears only if walkable overlays are enabled
		if PopochiuEditorConfig.get_editor_setting(
			PopochiuEditorConfig.GIZMOS_POLY_ENABLE_UNSELECTED_WA
		):
			btn_walkable_area_polygon.show()
		# If we are editing a clickable object, show gizmos buttons too.
		if _active_popochiu_object is PopochiuClickable:
			btn_baseline.show()
			btn_walk_to_point.show()
			btn_look_at_point.show()
		# Props may be obstacles on the navigation area.
		if _active_popochiu_object is PopochiuProp:
			btn_obstacle_polygon.show()
		# Walkable areas show their polygon toggle
		if _active_popochiu_object is PopochiuWalkableArea:
			btn_interaction_polygon.show()

	# If we are in a Character scene, show polygon, obstacle polygon and dialogpos
	# gizmo buttons.
	elif PopochiuEditorHelper.is_editing_character():
		btn_dialog_pos.show()
		btn_obstacle_polygon.show()

	# Compact mode hides labels regardless of button visibility.
	if PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.TOOLBAR_COMPACT_MODE):
		return

	# Label for visibility controls is always shown when toolbar is shown.
	label_view.show()
	# "Editing" label is shown only if at least one editing polygon button is visible.
	label_edit.visible = btn_interaction_polygon.visible or btn_obstacle_polygon.visible


# Make all buttons pop-up
func _reset_buttons_state() -> void:
	btn_markers.set_pressed_no_signal(true)
	btn_baseline.set_pressed_no_signal(true)
	btn_walk_to_point.set_pressed_no_signal(true)
	btn_look_at_point.set_pressed_no_signal(true)
	btn_dialog_pos.set_pressed_no_signal(true)
	_passive_scope = PopochiuGizmoPlugin.PASSIVE_SCOPE_SELECTED
	_update_passive_scope_button_visuals()
	# Polygon overlay buttons start from editor settings for unselected objects.
	btn_interaction_polygon.set_pressed_no_signal(
		PopochiuEditorConfig.get_editor_setting(
			PopochiuEditorConfig.GIZMOS_POLY_ENABLE_UNSELECTED_INT
		)
	)
	btn_obstacle_polygon.set_pressed_no_signal(
		PopochiuEditorConfig.get_editor_setting(
			PopochiuEditorConfig.GIZMOS_POLY_ENABLE_UNSELECTED_OBS
		)
	)
	btn_walkable_area_polygon.set_pressed_no_signal(
		PopochiuEditorConfig.get_editor_setting(
			PopochiuEditorConfig.GIZMOS_POLY_ENABLE_UNSELECTED_WA
		)
	)


# When the passive scope changes, we also update the button icon and tooltip to
# reflect the new scope and the action that will be performed on the next click.
func _update_passive_scope_button_visuals() -> void:
	if _passive_scope == PopochiuGizmoPlugin.PASSIVE_SCOPE_SELECTED:
		btn_passive_scope.icon = PASSIVE_SCOPE_ROOM_ICON
		btn_passive_scope.tooltip_text = "Show polygons for whole room"
	else:
		btn_passive_scope.icon = PASSIVE_SCOPE_SELECTED_ICON
		btn_passive_scope.tooltip_text = "Show polygons for selected object only"


#endregion
