@tool
extends HBoxContainer
## Used to show new buttons in the EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU (the top bar in the
## 2D editor) to select specific nodes in PopochiuClickable objects.

var _active_popochiu_object: Node = null
var _shown_helpers := []

# Add these variables to track polygon edit mode
var _is_editing_polygon := false
var _polygon_being_edited: Node = null

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
	btn_interaction_polygon.pressed.connect(_select_interaction_polygon)
	btn_obstacle_polygon.pressed.connect(_select_obstacle_polygon)

	# Connect to singleton signals
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	EditorInterface.get_editor_settings().settings_changed.connect(_on_gizmo_settings_changed)

	_set_toolbar_buttons_color()
	hide()


#endregion

#region Private ####################################################################################
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


func _select_interaction_polygon() -> void:
	# If we are editing the polygon, exit editing mode and
	# select the parent node back.
	if _is_editing_polygon && _polygon_being_edited != null:
		_exit_editing_mode()
		return

	# We are editing a popochiu object holding a polygon, so let's move on
	# and enter interaction / navigation editing mode.
 
	# This variable will hold the reference to the polygon we need to edit.
	var obj_polygon: Node2D = null

	# Let's find the node holding the polygon
	# Since different Popochiu Objects have different polygons (NavigationRegion2D
	# for Walkable Areas, InteractionPolygon2D for props, etc...) we tagged them
	# by a special metadata
	obj_polygon = PopochiuEditorHelper.get_first_child_by_group(
		_active_popochiu_object,
		PopochiuEditorHelper.POPOCHIU_OBJECT_POLYGON_GROUP
	)

	if obj_polygon == null:
		return

	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(obj_polygon)
	obj_polygon.show()

	# Enable edit mode
	_is_editing_polygon = true
	_polygon_being_edited = obj_polygon
	btn_interaction_polygon.set_pressed_no_signal(true)


func _select_obstacle_polygon() -> void:
	# If we are editing the polygon, exit editing mode and
	# select the parent node back.
	if _is_editing_polygon && _polygon_being_edited != null:
		_exit_editing_mode()
		return

	# We are editing a popochiu object holding a polygon, so let's move on
	# and enter obstacle editing mode.

	# Let's store a reference to the clickable being edited
	var selected_node := EditorInterface.get_selection().get_selected_nodes()[0]
	# This variable will hold the reference to the polygon we need to edit.
	var obstacle_polygon: NavigationObstacle2D = null

	# Let's find the node holding the polygon
	# Since different Popochiu Objects have different polygons (NavigationRegion2D
	# for Walkable Areas, InteractionPolygon2D for props, etc...) we tagged them
	# by a special metadata
	obstacle_polygon = selected_node.get_node_or_null("ObstaclePolygon")

	if obstacle_polygon == null:
		return

	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(obstacle_polygon)
	obstacle_polygon.show()

	# Enable edit mode
	_is_editing_polygon = true
	_polygon_being_edited = obstacle_polygon
	btn_obstacle_polygon.set_pressed_no_signal(true)


# This function is used to exit editing mode. It's called by the toolbar buttons
# polygons selector handlers when we are editing a polygon.
#
# NOTE: To keep the naming meaningful and avoid a mess with arguments (like, passing the button
# which makes little sense), it inspects the type of polygon to identify the
# button to pop. This requires a bit of maintenance, but the whole polygon thing does
# so...
func _exit_editing_mode() -> void:
	# Pop the right button on the toolbar, depending
	# on the type of the polygon being edited.
	if PopochiuEditorHelper.is_popochiu_obj_polygon(_polygon_being_edited):
		btn_interaction_polygon.set_pressed_no_signal(false)
	elif PopochiuEditorHelper.is_popochiu_obstacle_polygon(_polygon_being_edited):
		btn_obstacle_polygon.set_pressed_no_signal(false)

	# Clear selection
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(
		_polygon_being_edited.get_parent()
	)

	# Reset editing mode flags
	_is_editing_polygon = false
	_polygon_being_edited = null

	# Refresh the editor interface
	_on_selection_changed()


func _on_gizmo_settings_changed() -> void:
	# Pretty self explanatory
	_set_walkable_areas_visibility()
	_set_room_clickable_polygons_visibility()
	_set_toolbar_buttons_color()


# This overly complex function refreshes the whole interface after a sub-node (interaction
# or navigation polygon) of a clickable or walkable area has been selected/deselected.
#
# TODO: This function is here until we have a polygon gizmo that we can use to populate
# our transition polygons, something that would considerably simplify the code of this
# canvas menu plugin and of all and every clickable in the game!
func _on_selection_changed() -> void:
	# Only force polygon reselection if edit mode is active
	if _is_editing_polygon && _polygon_being_edited != null:
		var selected_nodes = EditorInterface.get_selection().get_selected_nodes()
		if selected_nodes.is_empty() || !(_polygon_being_edited in selected_nodes):
			EditorInterface.get_selection().clear()
			EditorInterface.get_selection().add_node(_polygon_being_edited)
			_polygon_being_edited.show()
			btn_interaction_polygon.set_pressed_no_signal(false)
			btn_obstacle_polygon.set_pressed_no_signal(false)
			if PopochiuEditorHelper.is_popochiu_obj_polygon(_polygon_being_edited):
				btn_interaction_polygon.set_pressed_no_signal(true)
			elif PopochiuEditorHelper.is_popochiu_obstacle_polygon(_polygon_being_edited):
				btn_obstacle_polygon.set_pressed_no_signal(true)
			_set_walkable_areas_visibility()
			_set_room_clickable_polygons_visibility()
			_set_buttons_visibility()
			return

	# Always reset the walkable areas visibility depending on the user preferences
	# Doing this immediately so, if this function exits early, the visibility is conditioned
	# by the editor settings (partially fixes #325).
	_set_walkable_areas_visibility()
	_set_room_clickable_polygons_visibility()

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
			# TODO: this is not a helper function, because we want to get
			# rid of this ASAP. The same logic is also in the function
			# _set_polygons_visibility() in the base Popochiu object
			# factory, and should be removed as well.
			for node in _active_popochiu_object.get_children():
				if PopochiuEditorHelper.is_popochiu_obj_polygon(node):
					node.hide()
				# This "if" solves "!p_node->is_inside_tree()" internal Godot error
				# The line inside is the logic we need to make this block work
				if EditorInterface.get_edited_scene_root() == _active_popochiu_object:
					EditorInterface.get_selection().add_node.call_deferred(_active_popochiu_object)
		# Reset the clickable reference and hide the toolbar
		# (restart from a blank state)
		_active_popochiu_object = null
		hide()
		# NOTE: Here we used to pop all the buttons up, by invoking _reset_buttons_state() but
		# this is undesirable, since it overrides the user's visibility choices for the session.
		# Leaving this comment here for future reference.

		# Reset the walkable areas visibility depending on the user preferences
		# Doing here because clicking on an empty area would hide the walkable areas
		# ignoring the editor settings (fixes #325)
		_set_walkable_areas_visibility()
		_set_room_clickable_polygons_visibility()
		return

	# We identify which PopochiuClickable we are working on in the editor.

	# Case 1:
	# There is only one selected node in the editor. It can be anything the user
	# clicked on, or the polygon selected by clicking the toolbar button.
	# (The user can never select the polygon directly because the node is not visible
	# in the scene tree)
	if EditorInterface.get_selection().get_selected_nodes().size() == 1:
		var selected_node = EditorInterface.get_selection().get_selected_nodes()[0]
		if PopochiuEditorHelper.is_popochiu_obj_polygon(selected_node):
			_active_popochiu_object = selected_node.get_parent()
		elif PopochiuEditorHelper.is_popochiu_room_object(selected_node):
			# Manage object polygons
			var polygon = null
			if is_instance_valid(_active_popochiu_object):
				# Maybe it's an interaction polygon?
				polygon = PopochiuEditorHelper.get_first_child_by_group(
					_active_popochiu_object,
					PopochiuEditorHelper.POPOCHIU_OBJECT_POLYGON_GROUP
				)
				if polygon == null:
					# Or maybe it's an obstacle polygon.
					polygon = _active_popochiu_object.get_node_or_null("ObstaclePolygon")
			if (polygon != null):
				polygon.hide()
			btn_interaction_polygon.set_pressed_no_signal(false)
			_active_popochiu_object = selected_node
		else:
			_active_popochiu_object = null

	# Case 2:
	# We have more than one node selected. This can happen because the user selected
	# more than one node explicitly (holding shift, or ctrl), or because the user selected
	# one node in the scene while editing the polygon.
	# In this case, since the polygon was selected programmatically and it's not in the scene
	# tree, Godot will NOT remove it from selection and we need to do it by hand.
	elif EditorInterface.get_selection().get_selected_nodes().size() > 1:
		for node in EditorInterface.get_selection().get_selected_nodes():
			if PopochiuEditorHelper.is_popochiu_obj_polygon(node):
				node.hide()
				EditorInterface.get_selection().remove_node.call_deferred(node)
				btn_interaction_polygon.set_pressed_no_signal(false)
			if PopochiuEditorHelper.is_popochiu_obstacle_polygon(node):
				node.hide()
				EditorInterface.get_selection().remove_node.call_deferred(node)
				btn_obstacle_polygon.set_pressed_no_signal(false)

	# Reset the walkable areas visibility depending on the user preferences
	# Doing this also at the end because the state can be reset by one of the steps
	# above.
	_set_walkable_areas_visibility()
	_set_room_clickable_polygons_visibility()

	# Always reset the button visibility depending on the state of the internal variables	
	_set_buttons_visibility()


# Handles the editor config that allows the WAs polygons to be always visible,
# not only during editing.
func _set_walkable_areas_visibility() -> void:
	# Avoid errors when the editor has no scene open
	if EditorInterface.get_edited_scene_root() == null:
		return

	# get_all_children returns an empty array if the node has no children
	# so we can safely iterate over it without checking for null
	for child in PopochiuEditorHelper.get_all_children(
		EditorInterface.get_edited_scene_root().find_child("WalkableAreas")
	):
		# Not a polygon? Skip
		if not PopochiuEditorHelper.is_popochiu_obj_polygon(child):
			continue
		# Should we show all the polygons? Show and go to the next one
		if PopochiuEditorConfig.get_editor_setting(
			PopochiuEditorConfig.GIZMOS_ALWAYS_SHOW_WA
		):
			child.show()
			continue
		# If we are editing the polygon, make sure it stays visible!
		if child in EditorInterface.get_selection().get_selected_nodes():
			child.show()
			continue
		# OK, we know we must hide this polygon now!
		child.hide()


# Handles the editor config that allows the room clickable polygons to be always visible,
# not only during editing. This includes props, characters, and hotspots.
func _set_room_clickable_polygons_visibility() -> void:
	# Avoid errors when the editor has no scene open
	if EditorInterface.get_edited_scene_root() == null:
		return

	var root := EditorInterface.get_edited_scene_root()

	# Handle character scene first (when editing a character directly)
	if PopochiuEditorHelper.is_editing_character():
		if PopochiuEditorHelper.is_character(root):
			_set_visibility_for_clickable_polygons(root)
			return

	# Handle room scene (when editing a room)
	# If we are not editing a room, we don't need to do anything.
	# Also, we prevent errors for accessing to nonexistent nodes.
	if not PopochiuEditorHelper.is_editing_room():
		return

	# Handle Props
	for child: Node in root.find_child("Props").get_children():
		if PopochiuEditorHelper.is_prop(child):
			_set_visibility_for_clickable_polygons(child)

	# Handle Characters
	for child: Node in root.find_child("Characters").get_children():
		if PopochiuEditorHelper.is_character(child):
			_set_visibility_for_clickable_polygons(child)

	# Handle Hotspots
	for child: Node in root.find_child("Hotspots").get_children():
		if PopochiuEditorHelper.is_hotspot(child):
			_set_visibility_for_clickable_polygons(child)


# Helper function to handle polygon visibility for both interaction and obstacle polygons
func _set_visibility_for_clickable_polygons(obj: Node) -> void:
	# Handle interaction polygon
	var interaction_polygon = PopochiuEditorHelper.get_first_child_by_group(
		obj,
		PopochiuEditorHelper.POPOCHIU_OBJECT_POLYGON_GROUP
	)
	if interaction_polygon != null:
		_set_polygon_visibility(
			interaction_polygon,
			PopochiuEditorConfig.GIZMOS_ALWAYS_SHOW_INT_POLY
		)

	# Handle obstacle polygon
	var obstacle_polygon: NavigationObstacle2D = obj.get_node_or_null("ObstaclePolygon")
	if obstacle_polygon != null:
		_set_polygon_visibility(
			obstacle_polygon,
			PopochiuEditorConfig.GIZMOS_ALWAYS_SHOW_OBS_POLY
		)


# Helper function to set polygon visibility based on editor settings and selection
func _set_polygon_visibility(polygon: Node, always_show_setting: String) -> void:
	# Should we show all polygons of this type? Show and continue
	if PopochiuEditorConfig.get_editor_setting(always_show_setting):
		polygon.show()
	# If we are editing the polygon, make sure it stays visible!
	elif polygon in EditorInterface.get_selection().get_selected_nodes():
		polygon.show()
	# OK, we know we must hide this polygon now!
	else:
		polygon.hide()


# Sets all the buttons color so that they are the same as the gizmos
# or make them theme-standard if the use so prefer (see editor settings)
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
		Color.RED # no config for this at the moment
	)
	_set_toolbar_button_color(
		btn_obstacle_polygon,
		Color.DARK_ORANGE # no config for this at the moment
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

	# If we're in polygon edit mode, only show the relevant button
	if _is_editing_polygon && _polygon_being_edited != null:
		show()
		if PopochiuEditorHelper.is_popochiu_obj_polygon(_polygon_being_edited):
			btn_interaction_polygon.show()
			btn_interaction_polygon.set_pressed_no_signal(true)
		elif PopochiuEditorHelper.is_popochiu_obstacle_polygon(_polygon_being_edited):
			btn_obstacle_polygon.show()
			btn_obstacle_polygon.set_pressed_no_signal(true)
		return

	# The rest of the existing visibility logic
	# If we are not in a room and we are not editing a Popochiu object, nothing to do
	if not (
		PopochiuEditorHelper.is_popochiu_room_object(_active_popochiu_object)
		or PopochiuEditorHelper.is_editing_room()
		or PopochiuEditorHelper.is_editing_character()
	):
		return

	# Now we know we have to show the toolbar
	show()

	# Every Popochiu clickable always shows the polygons editing buttons when selected
	# in a room scene. Same when the scene is a character scene.
	if (
		(
			PopochiuEditorHelper.is_editing_room()
			and PopochiuEditorHelper.is_popochiu_room_object(_active_popochiu_object)
		)
		or PopochiuEditorHelper.is_editing_character()
	):
		btn_interaction_polygon.show()

	# Only exception is: we are in a room scene and selected a character.
	# In this case, we don't want to show the polygon editing button.
	if (
		PopochiuEditorHelper.is_editing_room()
		and PopochiuEditorHelper.is_character(_active_popochiu_object)
	):
		btn_interaction_polygon.hide()

	# If the selected node in the editor is a popochiu interaction polygon we
	# hide the obstacle polygon button, and leave only the interaction polygon one.
	if PopochiuEditorHelper.is_popochiu_obj_polygon(
		EditorInterface.get_selection().get_selected_nodes()[0]
	):
		btn_interaction_polygon.show()
		btn_obstacle_polygon.hide()
		return

	# Viceversa if the selected node is an obstacle polygon, we just show
	# the obstacle polygon button.
	if PopochiuEditorHelper.is_popochiu_obstacle_polygon(
		EditorInterface.get_selection().get_selected_nodes()[0]
	):
		btn_interaction_polygon.hide()
		btn_obstacle_polygon.show()
		return

	# If we are in a room scene...
	if PopochiuEditorHelper.is_editing_room():
		# We always show the markers button
		btn_markers.show()
		# also, we may have selected a room object of sort, so check
		# for the various types and hide the ones we don't need.
		# If we are editing a clickable object, let's show gizmos buttons too.
		if _active_popochiu_object is PopochiuClickable:
			btn_baseline.show()
			btn_walk_to_point.show()
			btn_look_at_point.show()
		# Props may be obstacles on the navigation area.
		if _active_popochiu_object is PopochiuProp:
			btn_obstacle_polygon.show()

	# If we are in a Character scene, show polygon, obstacle polygon and dialogpos gizmo button.
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


#endregion