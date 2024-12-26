@tool
class_name PopochiuClickable
extends Area2D
## Handles an Area2D that reacts to mouse events.
##
## Is the base class for [PopochiuProp], [PopochiuHotspot] and [PopochiuCharacter].
## It has a property to determine when the object should render in front or back to other, another
## property that can be used to define the position to which characters will move to when moving
## to the item, and tow [CollisionPolygon2D] which are used to handle players interaction and
## handle scaling.

## Used to allow devs to define the cursor type for the clickable.
const CURSOR := preload("res://addons/popochiu/engine/cursor/cursor.gd")

## The identifier of the object used in scripts.
@export var script_name := ""
## The text shown to players when the cursor hovers the object.
@export var description := ""
## Whether the object will listen to interactions.
@export var clickable := true: set = set_clickable
## The [code]y[/code] position of the baseline relative to the center of the object.
@export var baseline := 0
## The [Vector2] position where characters will move when approaching the object.
@export var walk_to_point := Vector2.ZERO
## The [Vector2] position where characters will turn looking at the object.
@export var look_at_point := Vector2.ZERO
## The cursor to use when the mouse hovers the object.
@export var cursor: CURSOR.Type = CURSOR.Type.NONE
## Whether the object will be rendered always above other objects in the room.
@export var always_on_top := false
## Stores the vertices to assign to the [b]InteractionPolygon[/b] child during runtime. This is used
## by [PopochiuRoom] to store the info in its [code].tscn[/code].
@export var interaction_polygon := PackedVector2Array()
## Stores the position to assign to the [b]InteractionPolygon[/b] child during runtime. This is used
## by [PopochiuRoom] to store the info in its [code].tscn[/code].
@export var interaction_polygon_position := Vector2.ZERO

## The [PopochiuRoom] to which the object belongs.
var room: Node2D = null: set = set_room
## The number of times this object has been left-clicked.
var times_clicked := 0
## The number of times this object has been double-clicked.
var times_double_clicked := 0
## The number of times this object has been right-clicked.
var times_right_clicked := 0
## The number of times this object has been middle-clicked.
var times_middle_clicked := 0
# NOTE: Don't know if this will make sense, or if this object should emit a signal about the click
# 		(command execution).
## Stores the last [enum MouseButton] pressed on this object.
var last_click_button := -1

# Used for setting the double click delay. Windows default is 500 milliseconds.
var _double_click_delay: float = 0.2
# Used for tracking if a double click has occurred.
var _has_double_click: bool = false

@onready var _description_code := description


#region Godot ######################################################################################
func _ready():
	add_to_group("PopochiuClickable")

	if Engine.is_editor_hint():
		hide_helpers()

		# Add interaction polygon to the proper group
		if (get_node_or_null("InteractionPolygon") != null):
			get_node("InteractionPolygon").add_to_group(
				PopochiuEditorHelper.POPOCHIU_OBJECT_POLYGON_GROUP
			)

		# Ignore assigning the polygon when:
		if (
			get_node_or_null("InteractionPolygon") == null # there is no InteractionPolygon node
			or not get_parent() is Node2D # editing it in the .tscn file of the object directly
			or self is PopochiuCharacter # avoid resetting the polygon for characters (see issue #158))
		):
			return

		if interaction_polygon.is_empty():
			interaction_polygon = get_node("InteractionPolygon").polygon
			interaction_polygon_position = get_node("InteractionPolygon").position
		else:
			get_node("InteractionPolygon").polygon = interaction_polygon
			get_node("InteractionPolygon").position = interaction_polygon_position

		# If we are in the editor, we're done
		return

	# When the game is running...
	# Update the node's polygon when:
	if (
		get_node_or_null("InteractionPolygon") # there is an InteractionPolygon node
		and not self is PopochiuCharacter # avoids resetting the polygon (see issue #158)
	):
		get_node("InteractionPolygon").polygon = interaction_polygon
		get_node("InteractionPolygon").position = interaction_polygon_position

	visibility_changed.connect(_toggle_input)

	# Ignore this object if it is a temporary one (its name has *)
	if clickable and not "*" in name:
		# Connect to own signals
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
		# Fix #183 by listening only to inputs in this CollisionObject2D
		input_event.connect(_on_input_event)

		# Connect to singleton signals
		PopochiuUtils.e.language_changed.connect(_translate)

	_translate()


func _notification(event: int) -> void:
	if event == NOTIFICATION_EDITOR_PRE_SAVE:
		interaction_polygon = get_node("InteractionPolygon").polygon
		interaction_polygon_position = get_node("InteractionPolygon").position


#endregion

#region Virtual ####################################################################################
## Called when the room this node belongs to has been added to the tree.
## [i]Virtual[/i].
func _on_room_set() -> void:
	pass


## Called when the node is clicked.
## [i]Virtual[/i].
func _on_click() -> void:
	pass


## Called when the node is double clicked.
## [i]Virtual[/i].
func _on_double_click() -> void:
	pass


## Called when the node is right clicked.
## [i]Virtual[/i].
func _on_right_click() -> void:
	pass


## Called when the node is middle clicked.
## [i]Virtual[/i].
func _on_middle_click() -> void:
	pass


## Called when the node is clicked and there is an inventory item selected.
## [i]Virtual[/i].
func _on_item_used(item: PopochiuInventoryItem) -> void:
	pass


#endregion

#region Public #####################################################################################
## Used by the plugin to hide the visual helpers that show the interaction polygon
## in the 2D Canvas Editor when this node is unselected in the Scene panel.
func hide_helpers() -> void:
	if get_node_or_null("InteractionPolygon"):
		$InteractionPolygon.hide()


## Used by the plugin to make visible the visual helpers that show the interaction polygon
## in the 2D Canvas Editor when this node is unselected in the Scene panel.
func show_helpers() -> void:
	if get_node_or_null("InteractionPolygon"):
		$InteractionPolygon.show()


## Hides this Node.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_disable() -> Callable:
	return func(): await disable()


## Hides this Node.
func disable() -> void:
	self.visible = false

	await get_tree().process_frame


## Shows this Node.[br][br]
## [i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_enable() -> Callable:
	return func(): await enable()


## Shows this Node.
func enable() -> void:
	self.visible = true

	await get_tree().process_frame


## Returns the [member description] of the node using [method Object.tr] if
## [member PopochiuSettings.use_translations] is [code]true[/code]. Otherwise, it returns just the
## value of [member description].
func get_description() -> String:
	if Engine.is_editor_hint():
		if description.is_empty():
			description = name
		return description
	return PopochiuUtils.e.get_text(description)


## Called when the object is left clicked.
func on_click() -> void:
	await _on_click()


## Called when the object is double clicked.
func on_double_click() -> void:
	_reset_double_click()
	await _on_double_click()


## Called when the object is right clicked.
func on_right_click() -> void:
	await _on_right_click()


## Called when the object is middle clicked.
func on_middle_click() -> void:
	await _on_middle_click()


## Called when an [param item] is used on this object.
func on_item_used(item: PopochiuInventoryItem) -> void:
	await _on_item_used(item)
	# after item has been used return to normal state
	PopochiuUtils.i.active = null


## Triggers the proper GUI command for the clicked mouse button identified with [param button_idx],
## which can be [enum MouseButton].MOUSE_BUTTON_LEFT, [enum MouseButton].MOUSE_BUTTON_RIGHT or
## [enum MouseButton].MOUSE_BUTTON_MIDDLE.
func handle_command(button_idx: int) -> void:
	var command: String = PopochiuUtils.e.get_current_command_name().to_snake_case()
	var prefix := "on_%s"
	var suffix := "click"

	match button_idx:
		MOUSE_BUTTON_RIGHT:
			suffix = "right_" + suffix
		MOUSE_BUTTON_MIDDLE:
			suffix = "middle_" + suffix

	if not command.is_empty():
		var command_method := suffix.replace("click", command)

		if has_method(prefix % command_method):
			suffix = command_method

	PopochiuUtils.e.add_history({
		action = suffix if command.is_empty() else command,
		target = description
	})

	await call(prefix % suffix)


#endregion


#region SetGet #####################################################################################
func set_clickable(value: bool) -> void:
	clickable = value
	input_pickable = clickable


func set_room(value: Node2D) -> void:
	room = value

	_on_room_set()


#endregion

#region Private ####################################################################################
func _on_mouse_entered() -> void:
	if PopochiuUtils.e.hovered and is_instance_valid(PopochiuUtils.e.hovered) and (
		PopochiuUtils.e.hovered.get_parent() == self
		or get_index() < PopochiuUtils.e.hovered.get_index()
	):
		PopochiuUtils.e.add_hovered(self, true)
		return

	PopochiuUtils.e.add_hovered(self)

	PopochiuUtils.g.mouse_entered_clickable.emit(self)


func _on_mouse_exited() -> void:
	last_click_button = -1

	if PopochiuUtils.e.remove_hovered(self):
		PopochiuUtils.g.mouse_exited_clickable.emit(self)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if PopochiuUtils.g.is_blocked or not PopochiuUtils.e.hovered or PopochiuUtils.e.hovered != self:
		return

	if _is_double_click_or_tap(event):
		times_double_clicked += 1
		PopochiuUtils.e.clicked = self
		on_double_click()

		return

	if not await _is_click_or_touch_pressed(event): return

	var event_index := PopochiuUtils.get_click_or_touch_index(event)
	PopochiuUtils.e.clicked = self
	last_click_button = event_index

	get_viewport().set_input_as_handled()

	match event_index:
		MOUSE_BUTTON_LEFT:
			if PopochiuUtils.i.active:
				await on_item_used(PopochiuUtils.i.active)
			else:
				await handle_command(event_index)
				times_clicked += 1
		MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
			if PopochiuUtils.i.active: return

			await handle_command(event_index)

			if event_index == MOUSE_BUTTON_RIGHT:
				times_right_clicked += 1
			elif event_index == MOUSE_BUTTON_MIDDLE:
				times_middle_clicked += 1

	PopochiuUtils.e.clicked = null


func _toggle_input() -> void:
	if clickable:
		input_pickable = visible


func _translate() -> void:
	if (
		Engine.is_editor_hint()
		or not is_inside_tree()
		or not PopochiuUtils.e.settings.use_translations
	):
		return

	description = PopochiuUtils.e.get_text("%s-%s" % [get_tree().current_scene.name, _description_code])


# ---- @anthonyirwin82 -----------------------------------------------------------------------------
# NOTE: Temporarily duplicating PopochiuUtils functions here with an added delay for double click.
# Having delay in the PopochiuUtils class that other gui code calls introduced unwanted issues.
# This is a temporary work around until a more permanent solution is found.

# Checks if [param event] is an [InputEventMouseButton] or [InputEventScreenTouch] event.
func _is_click_or_touch(event: InputEvent) -> bool:
	if (
		(event is InputEventMouseButton and not event.double_click)
		or (event is InputEventScreenTouch and not event.double_tap)
	):
		# This delay is need to prevent a single click being detected before double click
		await PopochiuUtils.e.wait(_double_click_delay)

		if not _has_double_click:
			return (event is InputEventMouseButton or event is InputEventScreenTouch)

	return false


# Checks if [param event] is an [InputEventMouseButton] or [InputEventScreenTouch] event and if it
# is pressed.
func _is_click_or_touch_pressed(event: InputEvent) -> bool:
	# Fix #183 by including `event is InputEventScreenTouch` validation
	if not _has_double_click:
		return await _is_click_or_touch(event) and event.pressed
	else:
		return false


# Checks if [param event] is a double click or double tap event.
func _is_double_click_or_tap(event: InputEvent) -> bool:
	if (
		(event is InputEventMouseButton and event.double_click)
		or (event is InputEventScreenTouch and event.double_tap)
	):
		_has_double_click = true

		if event is InputEventMouseButton:
			return event.double_click
		elif event is InputEventScreenTouch:
			return event.double_tap

	return false


# Resets the double click status to false by default
func _reset_double_click(double_click: bool = false) -> void:
	# this delay is needed to prevent single click being detected after double click event
	await PopochiuUtils.e.wait(_double_click_delay)
	_has_double_click = double_click
# ----------------------------------------------------------------------------- @anthonyirwin82 ----


#endregion
