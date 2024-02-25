@tool
class_name PopochiuClickable
extends Area2D
## Handles an Area2D that reacts to mouse events.
##
## Is the base clase for [PopochiuProp], [PopochiuHotspot] and [PopochiuCharacter].
## It has a property to determine when the object should render in front or back to other, another
## property that can be used to define the position to which characters will move to when moving
## to the item, and tow [CollisionPolygon2D] which are used to handle players interaction and
## handle scaling.

## Used to allow devs to define the cursor type for the clickable.
const CURSOR := preload('res://addons/popochiu/engine/cursor/cursor.gd')

## The identifier of the object used in scripts.
@export var script_name := ''
## The text shown to players when the cursor hovers the object.
@export var description := ''
## Whether the object will listen to interactions.
@export var clickable := true
## The [code]y[/code] position of the baseline relative to the center of the object.
@export var baseline := 0 : set = set_baseline
## The [Vector2] position where characters will move when aproaching the object.
@export var walk_to_point := Vector2.ZERO : set = set_walk_to_point
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
var room: Node2D = null : set = set_room
## The number of times this object has been left-clicked.
var times_clicked := 0
## The number of times this object has been right-clicked.
var times_right_clicked := 0
## The number of times this object has been middle-clicked.
var times_middle_clicked := 0
## Used by the editor to know if the [b]InteractionPolygon[/b] child its being edited in Godot's
## 2D Canvas Editor.
var editing_polygon := false
## Stores the last [enum MouseButton] pressed on this object.
var last_click_button := -1 # NOTE Don't know if this will make sense, or if this object should
# emit a signal about the click (command execution).

@onready var _description_code := description


#region Godot ######################################################################################
func _ready():
	add_to_group('PopochiuClickable')
	
	if Engine.is_editor_hint():
		hide_helpers()
		
		# Ignore assigning the polygon when:
		if (
			get_node_or_null("InteractionPolygon") == null # there is no InteractionPolygon node
			or not get_parent() is Node2D # editing it in the .tscn file of the object directly
			or self is PopochiuCharacter # avoids reseting the polygon (see issue #158)
		):
			return
		
		if interaction_polygon.is_empty():
			interaction_polygon = get_node('InteractionPolygon').polygon
			interaction_polygon_position = get_node('InteractionPolygon').position
		else:
			get_node('InteractionPolygon').polygon = interaction_polygon
			get_node('InteractionPolygon').position = interaction_polygon_position
		
		return
	else:
		$BaselineHelper.free()
		$WalkToHelper.free()
		
		# Update the node's polygon when:
		if (
			get_node_or_null("InteractionPolygon") # there is an InteractionPolygon node
			and not self is PopochiuCharacter # avoids reseting the polygon (see issue #158)
		):
			get_node("InteractionPolygon").polygon = interaction_polygon
			get_node("InteractionPolygon").position = interaction_polygon_position
	
	visibility_changed.connect(_toggle_input)

	if clickable:
		# Connect to own signals
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
		
		# Connect to singleton signals
		E.language_changed.connect(_translate)
		G.blocked.connect(_on_graphic_interface_blocked)
		G.unblocked.connect(_on_graphic_interface_unblocked)
	
	set_process_unhandled_input(false)
	_translate()


func _unhandled_input(event: InputEvent):
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed:
		if not E.hovered or E.hovered != self: return
		
		E.clicked = self
		last_click_button = mouse_event.button_index
		
		get_viewport().set_input_as_handled()
		
		match mouse_event.button_index:
			MOUSE_BUTTON_LEFT:
				if I.active:
					on_item_used(I.active)
				else:
					handle_command(mouse_event.button_index)
					
					times_clicked += 1
			MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
				if I.active: return
				
				handle_command(mouse_event.button_index)
				
				if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
					times_right_clicked += 1
				else:
					times_middle_clicked += 1


func _process(delta):
	if Engine.is_editor_hint():
		if walk_to_point != get_node('WalkToHelper').position:
			walk_to_point = get_node('WalkToHelper').position
			
			notify_property_list_changed()
		elif baseline != get_node('BaselineHelper').position.y:
			baseline = get_node('BaselineHelper').position.y
			
			notify_property_list_changed()
		
		if editing_polygon:
			interaction_polygon = get_node('InteractionPolygon').polygon
			interaction_polygon_position = get_node('InteractionPolygon').position


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
## Used by the plugin to hide the visual helpers that show the [member baseline] and
## [member walk_to_point] in the 2D Canvas Editor when this node is unselected in the Scene panel.
func hide_helpers() -> void:
	$BaselineHelper.hide()
	$WalkToHelper.hide()
	
	if get_node_or_null("InteractionPolygon"):
		$InteractionPolygon.hide()


## Used by the plugin to make visible the visual helpers that show the [member baseline] and
## [member walk_to_point] of the object in the 2D Canvas Editor when the is selected in the
## Scene panel.
func show_helpers() -> void:
	$BaselineHelper.show()
	$WalkToHelper.show()
	
	if get_node_or_null("InteractionPolygon"):
		$InteractionPolygon.show()


## Hides this Node.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_disable() -> Callable:
	return func (): await disable()


## Hides this Node.
func disable() -> void:
	self.visible = false
	
	await get_tree().process_frame


## Shows this Node.
## [br][i]This method is intended to be used inside a [method Popochiu.queue] of instructions.[/i]
func queue_enable() -> Callable:
	return func (): await enable()


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
	return E.get_text(description)


## Returns the global position of [member walk_to_point].
func get_walk_to_point() -> Vector2:
	if Engine.is_editor_hint():
		return walk_to_point
	elif is_inside_tree():
		return to_global(walk_to_point)
	return walk_to_point


## Called when the object is left clicked.
func on_click() -> void:
	_on_click()


## Called when the object is right clicked.
func on_right_click() -> void:
	_on_right_click()


## Called when the object is middle clicked.
func on_middle_click() -> void:
	_on_middle_click()


## Called when an [param item] is used on this object.
func on_item_used(item: PopochiuInventoryItem) -> void:
	_on_item_used(item)


## Triggers the proper GUI command for the clicked mouse button identified with [param button_idx],
## which can be [enum MouseButton].MOUSE_BUTTON_LEFT, [enum MouseButton].MOUSE_BUTTON_RIGHT or
## [enum MouseButton].MOUSE_BUTTON_MIDDLE.
func handle_command(button_idx: int) -> void:
	var command: String = E.get_current_command_name().to_snake_case()
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
	
	E.add_history({
		action = suffix if command.is_empty() else command,
		target = description
	})
	
	await call(prefix % suffix)


#endregion

#endregion

#region SetGet #####################################################################################
func set_baseline(value: int) -> void:
	baseline = value
	
	if Engine.is_editor_hint() and get_node_or_null('BaselineHelper'):
		get_node('BaselineHelper').position = Vector2.DOWN * value


func set_walk_to_point(value: Vector2) -> void:
	walk_to_point = value
	
	if Engine.is_editor_hint() and get_node_or_null('WalkToHelper'):
		get_node('WalkToHelper').position = value


func set_room(value: Node2D) -> void:
	room = value
	
	_on_room_set()


#endregion

#region Private ####################################################################################
func _on_mouse_entered() -> void:
	set_process_unhandled_input(true)
	
	if E.hovered and is_instance_valid(E.hovered) and (
		E.hovered.get_parent() == self or get_index() < E.hovered.get_index()
	):
		E.add_hovered(self, true)
		return
	
	E.add_hovered(self)
	
	G.mouse_entered_clickable.emit(self)


func _on_mouse_exited() -> void:
	set_process_unhandled_input(false)
	
	last_click_button = -1
	
	if E.remove_hovered(self):
		G.mouse_exited_clickable.emit(self)


func _toggle_input() -> void:
	if clickable:
		input_pickable = visible
		set_process_unhandled_input(false)


func _translate() -> void:
	if Engine.is_editor_hint() or not is_inside_tree()\
	or not E.settings.use_translations: return
	
	description = E.get_text(
		'%s-%s' % [get_tree().current_scene.name, _description_code]
	)


func _on_graphic_interface_blocked() -> void:
	input_pickable = false
	set_process_unhandled_input(false)


func _on_graphic_interface_unblocked() -> void:
	input_pickable = true
	set_process_unhandled_input(true)


#endregion
