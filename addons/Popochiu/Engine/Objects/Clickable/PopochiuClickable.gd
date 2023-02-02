tool
class_name PopochiuClickable
extends Area2D
# Allows to handle an Area2D that reacts to click events, and mouse entering,
# and exiting.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

const CURSOR_TYPE := preload('res://addons/Popochiu/Engine/Cursor/Cursor.gd').Type

export var script_name := ''
export var description := ''
export var clickable := true
export var baseline := 0 setget set_baseline
export var walk_to_point: Vector2 setget set_walk_to_point, get_walk_to_point
export(CURSOR_TYPE) var cursor
export var always_on_top := false

var room: Node2D = null setget set_room # It is a PopochiuRoom
var times_clicked := 0
var times_right_clicked := 0

onready var _description_code := description


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready():
	add_to_group('PopochiuClickable')
	
	if Engine.editor_hint:
		hide_helpers()
		return
	else:
		$BaselineHelper.free()
		$WalkToHelper.free()
	
	connect('visibility_changed', self, '_toggle_input')

	if clickable:
		# Connect to own signals
		connect('mouse_entered', self, '_toggle_description', [true])
		connect('mouse_exited', self, '_toggle_description', [false])
		
		# Connect to singleton signals
		E.connect('language_changed', self, '_translate')
	
	set_process_unhandled_input(false)
	_translate()


func _unhandled_input(event):
	var mouse_event: = event as InputEventMouseButton 
	if mouse_event and mouse_event.pressed:
		if not E.hovered or E.hovered != self: return
		
		E.clicked = self
		if event.is_action_pressed('popochiu-interact'):
			get_tree().set_input_as_handled()
			
			if I.active:
				on_item_used(I.active)
			else:
				E.add_history({
					action = 'Interacted with: %s' % description
				})
				on_interact()
				
				times_clicked += 1
		elif event.is_action_pressed('popochiu-look'):
			if not I.active:
				E.add_history({
					action = 'Looked at: %s' % description
				})
				on_look()
				
				times_right_clicked += 1


func _process(delta):
	if Engine.editor_hint:
		if walk_to_point != get_node('WalkToHelper').position:
			walk_to_point = get_node('WalkToHelper').position
			property_list_changed_notify()
		elif baseline != get_node('BaselineHelper').position.y:
			baseline = get_node('BaselineHelper').position.y
			property_list_changed_notify()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
# When the room this node is in has been charged
func on_room_set() -> void:
	pass


# When the node is clicked
func on_interact() -> void:
	yield(E.run([
		G.display("Can't INTERACT with it")
	]), 'completed')


# When the node is right clicked
func on_look() -> void:
	yield(E.run([
		G.display("Can't EXAMINE it")
	]), 'completed')


# When the node is clicked and there is an inventory item selected
func on_item_used(item: PopochiuInventoryItem) -> void:
	yield(E.run([
		G.display("Can't USE %s here" % item.description)
	]), 'completed')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func hide_helpers() -> void:
	$BaselineHelper.hide()
	$WalkToHelper.hide()


func show_helpers() -> void:
	$BaselineHelper.show()
	$WalkToHelper.show()


# Hides the Node and disables its interaction
func disable(is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	self.visible = false
	yield(get_tree(), 'idle_frame')


# Makes the Node visible and enables its interaction
func enable(is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	self.visible = true
	yield(get_tree(), 'idle_frame')


func get_description() -> String:
	if Engine.editor_hint:
		if not description:
			description = name
		return description
	return E.get_text(description)


func disable_input() -> void:
	input_pickable = false
	set_process_unhandled_input(false)


func enable_input() -> void:
	input_pickable = true
	set_process_unhandled_input(false)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _toggle_description(display: bool) -> void:
	set_process_unhandled_input(display)
	
	if display:
		if E.hovered and is_instance_valid(E.hovered) and (
			E.hovered.get_parent() == self or get_index() < E.hovered.get_index()
		):
			E.add_hovered(self, true)
			return
		
		E.add_hovered(self)
		Cursor.set_cursor(cursor)
		
		if not I.active:
			G.show_info(description)
		else:
			G.show_info('Use %s with %s' % [I.active.description, description])
	else:
		if E.remove_hovered(self):
			Cursor.set_cursor()
			G.show_info()


func _toggle_input() -> void:
	if clickable:
		input_pickable = visible
		set_process_unhandled_input(false)


func _translate() -> void:
	if Engine.editor_hint or not is_inside_tree()\
	or not E.settings.use_translations: return
	
	description = E.get_text(
		'%s-%s' % [get_tree().current_scene.name, _description_code]
	)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func set_baseline(value: int) -> void:
	baseline = value
	
	if Engine.editor_hint and get_node_or_null('BaselineHelper'):
		get_node('BaselineHelper').position = Vector2.DOWN * value


func set_walk_to_point(value: Vector2) -> void:
	walk_to_point = value
	
	if Engine.editor_hint and get_node_or_null('WalkToHelper'):
		get_node('WalkToHelper').position = value


func get_walk_to_point() -> Vector2:
	if Engine.editor_hint:
		return walk_to_point
	elif is_inside_tree():
		return to_global(walk_to_point)
	return walk_to_point


func set_room(value: Node2D) -> void:
	room = value
	
	on_room_set()
