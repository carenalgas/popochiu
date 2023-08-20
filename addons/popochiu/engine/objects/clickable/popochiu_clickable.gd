@tool
class_name PopochiuClickable
extends Area2D
## Allows to handle an Area2D that reacts to click events, and mouse entering,
## and exiting.

const CURSOR := preload('res://addons/popochiu/engine/cursor/cursor.gd')

@export var script_name := ''
@export var description := ''
@export var clickable := true
@export var baseline := 0 : set = set_baseline
@export var walk_to_point := Vector2.ZERO : set = set_walk_to_point
@export var cursor: CURSOR.Type = CURSOR.Type.NONE
@export var always_on_top := false
@export var interaction_polygon := PackedVector2Array()
@export var interaction_polygon_position := Vector2.ZERO

var room: Node2D = null : set = set_room # It is a PopochiuRoom
var times_clicked := 0
var times_right_clicked := 0
var editing_polygon := false
var times_middle_clicked := 0
# NOTE Don't know if this will make sense, or if it this object should emit
# a signal about the click (command execution)
var last_click_button := -1

@onready var _description_code := description


#region Godot ######################################################################################
func _ready():
	add_to_group('PopochiuClickable')
	
	if Engine.is_editor_hint():
		hide_helpers()
		
		if get_node_or_null("InteractionPolygon") == null: return
		
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
		
		if get_node_or_null("InteractionPolygon"):
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
					_on_item_used(I.active)
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
## When the room this node belongs to has been added to the tree
func _on_room_set() -> void:
	pass


## When the node is clicked
func _on_click() -> void:
	pass


## When the node is right clicked
func _on_right_click() -> void:
	pass


## When the node is middle clicked
func _on_middle_click() -> void:
	pass


## When the node is clicked and there is an inventory item selected
func _on_item_used(item: PopochiuInventoryItem) -> void:
	pass


#endregion

#region Public #####################################################################################
func hide_helpers() -> void:
	$BaselineHelper.hide()
	$WalkToHelper.hide()
	
	if get_node_or_null("InteractionPolygon"):
		$InteractionPolygon.hide()


func show_helpers() -> void:
	$BaselineHelper.show()
	$WalkToHelper.show()
	
	if get_node_or_null("InteractionPolygon"):
		$InteractionPolygon.show()


func queue_disable() -> Callable:
	return func (): await disable()


# Hides the Node and disables its interaction
func disable() -> void:
	self.visible = false
	
	await get_tree().process_frame


func queue_enable() -> Callable:
	return func (): await enable()


# Makes the Node visible and enables its interaction
func enable() -> void:
	self.visible = true
	
	await get_tree().process_frame


func get_description() -> String:
	if Engine.is_editor_hint():
		if description.is_empty():
			description = name
		return description
	return E.get_text(description)


## Called when the object is left clicked
func on_click() -> void:
	_on_click()


## Called when the object is right clicked
func on_right_click() -> void:
	_on_right_click()


## Called when the object is middle clicked
func on_middle_click() -> void:
	_on_middle_click()


func on_item_used(item: PopochiuInventoryItem) -> void:
	await G.show_system_text("Can't USE %s here" % item.description)


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


func get_walk_to_point() -> Vector2:
	if Engine.is_editor_hint():
		return walk_to_point
	elif is_inside_tree():
		return to_global(walk_to_point)
	return walk_to_point


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
