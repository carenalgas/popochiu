@tool
extends HBoxContainer
## Used to show new buttons in the EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU (the top bar in the
## 2D editor) to toggle gizmo visibility for PopochiuClickable objects.

var _active_popochiu_object: Node = null
var _shown_helpers := []

@onready var btn_markers: Button = %BtnMarkers
@onready var btn_baseline: Button = %BtnBaseline
@onready var btn_walk_to_point: Button = %BtnWalkToPoint
@onready var btn_look_at_point: Button = %BtnLookAtPoint
@onready var btn_dialog_pos: Button = %BtnDialogPos
@onready var btn_interaction_polygon: Button = %BtnInteractionPolygon
@onready var btn_obstacle_polygon: Button = %BtnObstaclePolygon


#region Godot ######################################################################################
func _ready() -> void:
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

	# Connect to global signals
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	EditorInterface.get_editor_settings().settings_changed.connect(_on_gizmo_settings_changed)
	PopochiuEditorHelper.signal_bus.scene_changed.connect(_on_scene_changed)
	PopochiuEditorHelper.signal_bus.scene_closed.connect(_on_scene_closed)

	_set_toolbar_buttons_color()
	hide()


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
	PopochiuEditorHelper.signal_bus.gizmo_visibility_changed.emit(
		PopochiuGizmoPlugin.WALKABLE_AREA_POLYGON,
		btn_interaction_polygon.button_pressed
	)


# Toggle the obstacle polygon gizmo visibility via the signal bus.
func _toggle_obstacle_polygon_visibility() -> void:
	PopochiuEditorHelper.signal_bus.gizmo_visibility_changed.emit(
		PopochiuGizmoPlugin.OBSTACLE_POLYGON,
		btn_obstacle_polygon.button_pressed
	)


func _on_gizmo_settings_changed() -> void:
	_set_toolbar_buttons_color()


# Refreshes the toolbar after the editor selection changes.
func _on_selection_changed() -> void:
	# Make sure this function works only if the user is editing a
	# supported scene
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


# Sets all the buttons color so that they are the same as the gizmos
# or make them theme-standard if the user so prefers (see editor settings)
func _set_toolbar_buttons_color() -> void:
	if not PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_COLOR_TOOLBAR_BUTTONS):
		# Reset button colors
		_reset_toolbar_button_color(btn_markers)
		_reset_toolbar_button_color(btn_baseline)
		_reset_toolbar_button_color(btn_walk_to_point)
		_reset_toolbar_button_color(btn_look_at_point)
		_reset_toolbar_button_color(btn_dialog_pos)
		_reset_toolbar_button_color(btn_interaction_polygon)
		_reset_toolbar_button_color(btn_obstacle_polygon)
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
	_set_toolbar_button_color(
		btn_interaction_polygon,
		PopochiuEditorConfig.get_editor_setting(
			PopochiuEditorConfig.GIZMOS_INTERACTION_POLYGON_COLOR)
	)
	_set_toolbar_button_color(
		btn_obstacle_polygon,
		PopochiuEditorConfig.get_editor_setting(
			PopochiuEditorConfig.GIZMOS_OBSTACLE_POLYGON_COLOR)
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


func _set_buttons_visibility() -> void:
	# Let's assume the buttons are all hidden...
	hide()
	btn_markers.hide()
	btn_baseline.hide()
	btn_walk_to_point.hide()
	btn_look_at_point.hide()
	btn_dialog_pos.hide()
	btn_interaction_polygon.hide()
	btn_obstacle_polygon.hide()

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


# Make all buttons pop-up
func _reset_buttons_state() -> void:
	btn_markers.set_pressed_no_signal(true)
	btn_baseline.set_pressed_no_signal(true)
	btn_walk_to_point.set_pressed_no_signal(true)
	btn_look_at_point.set_pressed_no_signal(true)
	btn_dialog_pos.set_pressed_no_signal(true)
	btn_interaction_polygon.set_pressed_no_signal(false)
	btn_obstacle_polygon.set_pressed_no_signal(false)


#endregion
