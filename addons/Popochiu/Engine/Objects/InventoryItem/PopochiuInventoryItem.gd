extends TextureRect
class_name InventoryItem, 'res://addons/Popochiu/icons/inventory_item.png'
# An inventory item
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


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Cuando se le hace clic en el inventario
func on_interact() -> void:
	emit_signal('selected', self)


# Lo que pasará cuando se haga clic derecho en el icono del inventario
func on_look() -> void:
	pass


# Lo que pasará cuando se use otro InventoryItem del inventario sobre este
func on_item_used(_item: InventoryItem) -> void:
	pass


# Lo que pasará después de que se haya agregado el objeto al inventario.
func added_to_inventory() -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func set_in_inventory(value: bool) -> void:
	in_inventory = value
	
	if in_inventory: added_to_inventory()


func get_description() -> String:
	if Engine.editor_hint:
		if not description:
			description = name
		return description
	return E.get_text(description)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _toggle_description(display: bool) -> void:
	Cursor.set_cursor(cursor if display else null)
	G.show_info(description if display else '')
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
