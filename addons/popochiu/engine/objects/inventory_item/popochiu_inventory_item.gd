@icon('res://addons/popochiu/icons/inventory_item.png')
extends TextureRect
class_name PopochiuInventoryItem
# An inventory item.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

const CURSOR := preload('res://addons/popochiu/engine/cursor/cursor.gd')

signal description_toggled(description)
signal selected(item)

@export var description := '' : get = get_description
@export var stack := false
@export var script_name := ''
@export var cursor: CURSOR.Type = CURSOR.Type.USE

var amount := 1
var in_inventory := false : set = set_in_inventory


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready():
	mouse_entered.connect(_toggle_description.bind(true))
	mouse_exited.connect(_toggle_description.bind(false))
	gui_input.connect(_on_action_pressed)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
# When the item is clicked in the Inventory
func _on_click() -> void:
	pass


# When the item is right clicked in the Inventory
func _on_right_click() -> void:
	pass


# When the item is clicked and there is another inventory item selected
func _on_item_used(item: PopochiuInventoryItem) -> void:
	pass


# Actions to excecute after the item is added to the Inventory
func _on_added_to_inventory() -> void:
	pass


# Actions to excecute when the item is discarded from the Inventory
func _on_discard() -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func add(animate := true) -> Callable:
	return func (): await add_now(animate)


func add_now(animate := true) -> void:
	await I.add_item_now(script_name, animate)


func add_as_active(animate := true) -> Callable:
	return func (): await add_as_active_now(animate)


func add_as_active_now(animate := true) -> void:
	await I.add_item_now(script_name, animate)
	I.set_active_item(self, false)


func remove(animate := true) -> Callable:
	return func (): await remove_now(animate)


func remove_now(animate := true) -> void:
	await I.remove_item_now(script_name, animate)


func set_active(ignore_block := false) -> void:
	I.set_active_item(self, ignore_block)


# When the item is clicked in the Inventory
func on_click() -> void:
	selected.emit(self)


# When the item is right clicked in the Inventory
func on_right_click() -> void:
	await E.run([G.display('Nothing to see in this item')])


# When the item is clicked and there is another inventory item selected
func on_item_used(item: PopochiuInventoryItem) -> void:
	await E.run([
		G.display('Nothing happens when using %s in this item' % item.description)
	])


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func set_in_inventory(value: bool) -> void:
	in_inventory = value
	
	if in_inventory: _on_added_to_inventory()


func get_description() -> String:
	if Engine.is_editor_hint():
		if description.is_empty():
			description = name
		return description
	return E.get_text(description)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _toggle_description(display: bool) -> void:
	Cursor.set_cursor(cursor if display else CURSOR.Type.NONE)
	G.show_info(self.description if display else '')
	if display:
		description_toggled.emit(description if description else script_name)
	else:
		description_toggled.emit('')


func _on_action_pressed(event: InputEvent) -> void: 
	var mouse_event := event as InputEventMouseButton 
	if mouse_event:
		if mouse_event.is_action_pressed('popochiu-interact'):
			if I.active:
				_on_item_used(I.active)
			else:
				_on_click()
		elif mouse_event.is_action_pressed('popochiu-look'):
			_on_right_click()
