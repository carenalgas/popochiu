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
func queue_add(animate := true) -> Callable:
	return func (): await add(animate)


func add(animate := true) -> void:
	if I.is_full():
		printerr(
			"[Popochiu] Couldn't add %s. Inventory is full." %\
			script_name
		)
		
		await get_tree().process_frame
		return
	
	if not in_inventory:
		G.block()

		I.items.append(script_name)
		
		I.item_added.emit(self, animate)
		in_inventory = true
		
		await I.item_add_done

		G.done(true)

		return
	
	await get_tree().process_frame


func queue_add_as_active(animate := true) -> Callable:
	return func (): await add_as_active(animate)


func add_as_active(animate := true) -> void:
	await add(animate)
	
	I.set_active_item(self)


func queue_remove(animate := false) -> Callable:
	return func (): await remove(animate)


func remove(animate := false) -> void:
	in_inventory = false
	
	I.items.erase(script_name)
	I.set_active_item(null)
	# TODO: Maybe this signal should be triggered once the await has finished
	I.item_removed.emit(self, animate)
	
	await I.item_remove_done


func queue_discard(animate := false) -> Callable:
	return func (): await discard(animate)


func discard(animate := false) -> void:
	_on_discard()
	
	I.items.erase(script_name)
	I.item_discarded.emit(self)
	
	await remove(animate)


func set_active(ignore_block := false) -> void:
	I.set_active_item(self, ignore_block)


# When the item is clicked in the Inventory
func on_click() -> void:
	selected.emit(self)


# When the item is right clicked in the Inventory
func on_right_click() -> void:
	await G.display('Nothing to see in this item')


# When the item is clicked and there is another inventory item selected
func on_item_used(item: PopochiuInventoryItem) -> void:
	await G.display(
		'Nothing happens when using %s in this item' % item.description
	)


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
	Cursor.set_cursor(cursor if display else CURSOR.Type.IDLE)
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
