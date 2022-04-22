extends Control

signal item_added(item)

var is_disabled := false

var _can_hide_inventory := true

onready var _hide_y := rect_position.y - (rect_size.y - 4)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready():
	rect_position.y = _hide_y
	
	# Check if there are already items in the inventory (set manually in the scene)
	for ii in $Box.get_children():
		if ii is InventoryItem:
			ii.in_inventory = true
			ii.connect('description_toggled', self, '_show_item_info')
			ii.connect('selected', self, '_change_cursor')
	
	# Conectarse a señales del yo
	connect('mouse_entered', self, '_open')
	connect('mouse_exited', self, '_close')
	
	# Conectarse a las señales del papá de los inventarios
	I.connect('item_added', self, '_add_item')
	I.connect('item_removed', self, '_remove_item')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func disable() -> void:
	is_disabled = true
	
	$Tween.interpolate_property(
		self, 'rect_position:y',
		_hide_y, _hide_y - 3.5,
		0.3, Tween.TRANS_LINEAR, Tween.EASE_OUT
	)
	$Tween.start()


func enable() -> void:
	is_disabled = false
	
	$Tween.interpolate_property(
		self, 'rect_position:y',
		_hide_y - 3.5, _hide_y,
		0.3, Tween.TRANS_SINE, Tween.EASE_OUT
	)
	$Tween.start()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _open() -> void:
	if not is_disabled and rect_position.y != _hide_y: return
	
	$Tween.interpolate_property(
		self, 'rect_position:y',
		_hide_y if not is_disabled else rect_position.y, 0.0,
		0.5, Tween.TRANS_EXPO, Tween.EASE_OUT
	)
	$Tween.start()


func _close() -> void:
	yield(get_tree(), 'idle_frame')
	
	if not _can_hide_inventory: return
	
	$Tween.interpolate_property(
		self, 'rect_position:y',
		0.0, _hide_y if not is_disabled else _hide_y - 3.5,
		0.2, Tween.TRANS_SINE, Tween.EASE_IN
	)
	$Tween.start()


func _show_item_info(description := '') -> void:
	_can_hide_inventory = false if description else true


func _change_cursor(item: InventoryItem) -> void:
	I.set_active_item(item)


func _add_item(item: InventoryItem, animate := true) -> void:
	$Box.add_child(item)
	
	item.connect('description_toggled', self, '_show_item_info')
	item.connect('selected', self, '_change_cursor')
	
	if animate:
		_open()
		yield(get_tree().create_timer(2.0), 'timeout')
		_close()

	I.emit_signal('item_add_done', item)


func _remove_item(item: InventoryItem) -> void:
	item.disconnect('description_toggled', self, '_show_item_info')
	item.disconnect('selected', self, '_change_cursor')
	
	$Box.remove_child(item)
	
	yield(get_tree(), 'idle_frame')
	
	I.emit_signal('item_remove_done', item)
