@tool
extends HBoxContainer
## Used to show new buttons in the EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU (the top bar in the
## 2D editor) to select specific nodes in PopochiuClickable objects.

var _active_popochiu_object: Node = null
var _shown_helpers := []

@onready var btn_baseline: Button = %BtnBaseline
@onready var btn_walk_to_point: Button = %BtnWalkToPoint
@onready var btn_dialog_pos: Button = %BtnDialogPos
@onready var btn_interaction_polygon: Button = %BtnInteractionPolygon


#region Godot ######################################################################################
func _ready() -> void:
	# Gizmos are always visible at editor load, so we'll set the buttons down
	# to sync the status (hardcoded, not very good but enough for now)
	btn_baseline.set_pressed_no_signal(true)
	btn_walk_to_point.set_pressed_no_signal(true)
	btn_dialog_pos.set_pressed_no_signal(true)

	# Connect to child signals
	btn_baseline.pressed.connect(_toggle_baseline_visibility)
	btn_walk_to_point.pressed.connect(_toggle_walk_to_point_visibility)
	btn_dialog_pos.pressed.connect(_toggle_dialog_pos_visibility)
	btn_interaction_polygon.pressed.connect(_select_interaction_polygon)

	# Connect to singleton signals
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)

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
	obj_polygon = PopochiuEditorHelper.get_first_child_by_metadata(
		_active_popochiu_object,
		"POPOCHIU_OBJ_POLYGON_GIZMO"
	)
	
	if obj_polygon == null:
		return

	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(obj_polygon)
	if PopochiuEditorHelper.is_popochiu_room_object(obj_polygon):
		# Used to auto-bake navigation polygons
		obj_polygon.get_parent().editing_polygon = true
	obj_polygon.show()



func _on_selection_changed():
	# Make sure this function works only if the user is editing a
	# supported scene
	if not PopochiuEditorHelper.is_popochiu_object(
		EditorInterface.get_edited_scene_root()
	):
		return

	# Reset the clickable reference and hide the toolbar
	# (restart from a blank state)
	_active_popochiu_object = null
	hide()

	# If we have no selection in the tree (the user clicked on an
	# empty area, or similar), we pop all the buttons up and
	# leave the toolbar hidden.
	if EditorInterface.get_selection().get_selected_nodes().is_empty():
		_release_all_buttons()
		return

	# We identify which PopochiuClickable we are working on in the editor._active

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
			_active_popochiu_object = selected_node


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

	# Always reset the button visibility depending on the state of the internal variables	
	_set_buttons_visibility()


func _set_buttons_visibility():
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
func _release_all_buttons() -> void:
	for button: Button in get_children():
		button.set_pressed_no_signal(false)
