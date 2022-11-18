extends TextureRect
class_name PopochiuInventoryItem, 'res://addons/Popochiu/icons/inventory_item.png'
# An inventory item.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

const CURSOR_TYPE := preload('res://addons/Popochiu/Engine/Cursor/Cursor.gd').Type

signal description_toggled(description)
signal selected(item)

export var description := '' setget ,get_description
export var stack := false
export var script_name := ''
export(CURSOR_TYPE) var cursor

var amount := 1
var in_inventory := false setget set_in_inventory


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready():
	connect('mouse_entered', self, '_toggle_description', [true])
	connect('mouse_exited', self, '_toggle_description', [false])
	connect('gui_input', self, '_on_action_pressed')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
# When the item is clicked in the Inventory
func on_interact() -> void:
	emit_signal('selected', self)


# When the item is right clicked in the Inventory
func on_look() -> void:
	yield(E.run([
		G.display('Nothing to see in this item')
	]), 'completed')


# When the item is clicked and there is another inventory item selected
func on_item_used(item: PopochiuInventoryItem) -> void:
	yield(E.run([
		G.display('Nothing happens when using %s in this item' % item.description)
	]), 'completed')


# Actions to excecute after the item is added to the Inventory
func on_added_to_inventory() -> void:
	pass


# Actions to excecute when the item is discarded from the Inventory
func on_discard() -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func set_in_inventory(value: bool) -> void:
	in_inventory = value
	
	if in_inventory: on_added_to_inventory()


func get_description() -> String:
	if Engine.editor_hint:
		if not description:
			description = name
		return description
	return E.get_text(description)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _toggle_description(display: bool) -> void:
	Cursor.set_cursor(cursor if display else null)
	G.show_info(self.description if display else '')
	if display:
		emit_signal(
			'description_toggled', description if description else script_name
		)
	else:
		emit_signal('description_toggled', '')


func _on_action_pressed(event: InputEvent) -> void: 
	var mouse_event := event as InputEventMouseButton 
	if mouse_event:
		if mouse_event.is_action_pressed('popochiu-interact'):
			if I.active:
				on_item_used(I.active)
			else:
				on_interact()
		elif mouse_event.is_action_pressed('popochiu-look'):
			on_look()
