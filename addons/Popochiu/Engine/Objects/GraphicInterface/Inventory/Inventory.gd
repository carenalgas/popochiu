extends Control

var is_disabled := false

var _can_hide_inventory := true

onready var _hide_y := rect_position.y - (rect_size.y - 4)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready():
	rect_position.y = _hide_y
	
	# Check if there are already items in the inventory (set manually in the scene)
	for ii in $Box.get_children():
		if ii is PopochiuInventoryItem:
			ii.in_inventory = true
			ii.connect('description_toggled', self, '_show_item_info')
			ii.connect('selected', self, '_change_cursor')
	
	# Conectarse a señales del yo
	connect('mouse_entered', self, '_open')
	connect('mouse_exited', self, '_close')
	
	# Conectarse a las señales del papá de los inventarios
	I.connect('item_added', self, '_add_item')
	I.connect('item_removed', self, '_remove_item')
	I.connect('inventory_show_requested', self, '_show_and_hide')
	I.connect('inventory_hide_requested', self, 'disable')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func disable(use_tween := true) -> void:
	is_disabled = true
	
	if use_tween:
		$Tween.interpolate_property(
			self, 'rect_position:y',
			_hide_y, _hide_y - 4.5,
			0.3, Tween.TRANS_LINEAR, Tween.EASE_OUT
		)
		$Tween.start()
	else:
		$Tween.remove_all()
		rect_position.y = _hide_y - 4.5


func enable() -> void:
	is_disabled = false
	
	$Tween.interpolate_property(
		self, 'rect_position:y',
		_hide_y - 3.5, _hide_y,
		0.3, Tween.TRANS_SINE, Tween.EASE_OUT
	)
	$Tween.start()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
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


func _change_cursor(item: PopochiuInventoryItem) -> void:
	I.set_active_item(item)


func _add_item(item: PopochiuInventoryItem, animate := true) -> void:
	$Box.add_child(item)
	
	item.connect('description_toggled', self, '_show_item_info')
	item.connect('selected', self, '_change_cursor')
	
	if animate:
		_open()
		yield(get_tree().create_timer(2.0), 'timeout')
		_close()
	else:
		yield(get_tree(), 'idle_frame')

	I.emit_signal('item_add_done', item)


func _remove_item(item: PopochiuInventoryItem) -> void:
	item.disconnect('description_toggled', self, '_show_item_info')
	item.disconnect('selected', self, '_change_cursor')
	
	$Box.remove_child(item)
	
	yield(get_tree(), 'idle_frame')
	
	I.emit_signal('item_remove_done', item)


func _show_and_hide(time := 1.0) -> void:
	_open()
	
	yield($Tween, 'tween_all_completed')
	yield(E.wait(time, false), 'completed')
	
	_close()
	
	yield($Tween, 'tween_all_completed')
	
	I.emit_signal('inventory_shown')
