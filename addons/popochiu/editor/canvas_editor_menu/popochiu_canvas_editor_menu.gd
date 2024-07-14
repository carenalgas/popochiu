@tool
extends HBoxContainer
## Used to show new buttons in the EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU (the top bar in the
## 2D editor) to select specific nodes in PopochiuClickable objects.

var _active_popochiu_object: Node = null
var _shown_helpers := []

@onready var btn_baseline: Button = %BtnBaseline
@onready var btn_walk_to_point: Button = %BtnWalkToPoint
@onready var btn_look_at_point: Button = %BtnLookAtPoint
@onready var btn_dialog_pos: Button = %BtnDialogPos
@onready var btn_interaction_polygon: Button = %BtnInteractionPolygon


#region Godot ######################################################################################
func _ready() -> void:
	# Gizmos are always visible at editor load, so we'll set the buttons down
	# to sync the status (hardcoded, not very good but enough for now)
	_reset_buttons_state()

	# Connect to child signals
	btn_baseline.pressed.connect(_toggle_baseline_visibility)
	btn_walk_to_point.pressed.connect(_toggle_walk_to_point_visibility)
	#btn_look_at_point.pressed.connect(_toggle_look_at_point_visibility)
	btn_dialog_pos.pressed.connect(_toggle_dialog_pos_visibility)
	btn_interaction_polygon.pressed.connect(_select_interaction_polygon)

	# Connect to singleton signals
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	EditorInterface.get_editor_settings().settings_changed.connect(_on_gizmo_settings_changed)

	_set_toolbar_buttons_color()
	hide()

#endregion

#region Private ####################################################################################
func _toggle_walk_to_point_visibility() -> void:
	PopochiuEditorHelper.signal_bus.gizmo_visibility_changed.emit(
		PopochiuGizmoClickablePlugin.WALK_TO_POINT,
		btn_walk_to_point.button_pressed
	)


func _toggle_baseline_visibility() -> void:
	PopochiuEditorHelper.signal_bus.gizmo_visibility_changed.emit(
		PopochiuGizmoClickablePlugin.BASELINE,
		btn_baseline.button_pressed
	)


func _toggle_dialog_pos_visibility() -> void:
	PopochiuEditorHelper.signal_bus.gizmo_visibility_changed.emit(
		PopochiuGizmoClickablePlugin.DIALOG_POS,
		btn_dialog_pos.button_pressed
	)


func _select_interaction_polygon() -> void:
	# Since we are going to select the interaction polygon node
	# inside the node, let's hide the gizmos buttons
	btn_walk_to_point.hide()
	btn_baseline.hide()

	# If we are editing the polygon, go back and select the parent node
	# then stop execution.
	var selected_node := EditorInterface.get_selection().get_selected_nodes()[0]
	if PopochiuEditorHelper.is_popochiu_obj_polygon(
		selected_node
	):
		EditorInterface.get_selection().add_node(selected_node.get_parent())
		_on_selection_changed()
		return

	# If we are editing a popochiu object holding a polygon, let's move on.

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


func _on_gizmo_settings_changed() -> void:
	# Pretty self explanatory
	_set_walkable_areas_visibility()
	_set_toolbar_buttons_color()


func _on_selection_changed() -> void:
	# Make sure this function works only if the user is editing a
	# supported scene
	if not PopochiuEditorHelper.is_popochiu_object(
		EditorInterface.get_edited_scene_root()
	):
		hide()
		return

	# If we have no selection in the tree (the user clicked on an
	# empty area or pressed ESC), we pop all the buttons up and
	# leave the toolbar hidden.
	if EditorInterface.get_selection().get_selected_nodes().is_empty():
		if _active_popochiu_object != null:
			# TODO: this is not a helper function, because we want to get
			# rid of this ASAP. The same logic is also in the function
			# _set_polygons_visibility() in the base Popochiu object
			# factory, and should be removed as well.
			for node in _active_popochiu_object.get_children():
				if PopochiuEditorHelper.is_popochiu_obj_polygon(node):
					node.hide()
				EditorInterface.get_selection().add_node.call_deferred(_active_popochiu_object)
		# Reset the clickable reference and hide the toolbar
		# (restart from a blank state)
		_active_popochiu_object = null
		hide()
		_reset_buttons_state()
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
			var polygon = PopochiuEditorHelper.get_first_child_by_group(
				_active_popochiu_object,
				PopochiuEditorHelper.POPOCHIU_OBJECT_POLYGON_GROUP
			)
			if (polygon != null):
				polygon.hide()
			btn_interaction_polygon.set_pressed_no_signal(false)
			_active_popochiu_object = selected_node
		else:
			_active_popochiu_object = null

	# Case 2:
	# We have more than one node selected. This can happen because the user selected
	# more than one node explicitely (holding shift, or ctrl), or because the user selected
	# one node in the scene while editing the polygon.
	# In this case, since the polygon was selected programmatically and it's not in the scene
	# tree, Godot will NOT remove it from selection and we need to do it by hand.
	elif EditorInterface.get_selection().get_selected_nodes().size() > 1:
		for node in EditorInterface.get_selection().get_selected_nodes():
			if PopochiuEditorHelper.is_popochiu_obj_polygon(node):
				node.hide()
				EditorInterface.get_selection().remove_node.call_deferred(node)
				btn_interaction_polygon.set_pressed_no_signal(false)

	# Always reset the walkable areas visibility depending on the user preferences
	_set_walkable_areas_visibility()
	# Always reset the button visibility depending on the state of the internal variables	
	_set_buttons_visibility()


## Handles the editor config that allows the WAs polygons to be always visible,
## not only during editing.
func _set_walkable_areas_visibility() -> void:
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


## Sets all the buttons color so that they are the same as the gizmos
## or make them theme-standard if the use so prefer (see editor settigs)
func _set_toolbar_buttons_color() -> void:
	if not PopochiuEditorConfig.get_editor_setting(PopochiuEditorConfig.GIZMOS_COLOR_TOOLBAR_BUTTONS):
		# Reset button colors
		_reset_toolbar_button_color(btn_baseline)
		_reset_toolbar_button_color(btn_walk_to_point)
		_reset_toolbar_button_color(btn_look_at_point)
		_reset_toolbar_button_color(btn_dialog_pos)
		_reset_toolbar_button_color(btn_interaction_polygon)
		# Done
		return

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


## Internal helper to reduce code duplication
func _set_toolbar_button_color(btn, color) -> void:
	btn.add_theme_color_override("icon_normal_color", color)
	btn.add_theme_color_override("icon_hover_color", color.lightened(1.0))
	btn.add_theme_color_override("icon_focused_color", color.lightened(1.0))
	btn.add_theme_color_override("icon_pressed_color", color.darkened(0.2))
	btn.add_theme_color_override("icon_hover_pressed_color", color.lightened(1.0))


## Internal helper to reduce code duplication
func _reset_toolbar_button_color(btn) -> void:
	btn.remove_theme_color_override("icon_normal_color")
	btn.remove_theme_color_override("icon_hover_color")
	btn.remove_theme_color_override("icon_focused_color")
	btn.remove_theme_color_override("icon_pressed_color")
	btn.remove_theme_color_override("icon_hover_pressed_color")


func _set_buttons_visibility() -> void:
	# Let's assume the buttons are all hidden...
	hide()
	btn_baseline.hide()
	btn_walk_to_point.hide()
	btn_dialog_pos.hide()
	btn_interaction_polygon.hide()

	# If we are not editing a Popochiu object, nothing to do
	if not PopochiuEditorHelper.is_popochiu_room_object(_active_popochiu_object):
		return

	# Now we know we have to show the toolbar
	show()

	# Every Popochiu Object always shows the polygon editing button when edited
	# unless we are in a room scene and selected a character
	if not (
		PopochiuEditorHelper.is_character(_active_popochiu_object)
		and PopochiuEditorHelper.is_editing_room()
	):
		btn_interaction_polygon.show()
	
	# If the selected node in the editor is actually a popochiu object polygon
	# We don't have to show the other buttons, only the polygon editing toggle
	if PopochiuEditorHelper.is_popochiu_obj_polygon(
		EditorInterface.get_selection().get_selected_nodes()[0]
	):
		return

	# If we are in a room scene, we may have selected a room object of sort, so check
	# for the various types and hide the ones we don't need
	if PopochiuEditorHelper.is_room(EditorInterface.get_edited_scene_root()):
		# If we are editing a clickable object, let's show gizmos buttons too
		if _active_popochiu_object is PopochiuClickable:
			btn_baseline.show()
			btn_walk_to_point.show()

	# If we are in a Character scene, show polygon and dialogpos gizmo button
	elif PopochiuEditorHelper.is_character(EditorInterface.get_edited_scene_root()):
		btn_dialog_pos.show()


# Make all buttons pop-up
func _reset_buttons_state() -> void:
	btn_baseline.set_pressed_no_signal(true)
	btn_walk_to_point.set_pressed_no_signal(true)
	#btn_look_at_point.set_pressed_no_signal(true)
	btn_dialog_pos.set_pressed_no_signal(true)
