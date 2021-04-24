extends Control

signal item_added(item)

var _can_hide_inventory := true
var _is_disabled := false

onready var _hide_y := rect_position.y - (rect_size.y - 3.5)
onready var _foreground: TextureRect = find_node('InventoryForeground')
onready var _grid: GridContainer = find_node('InventoryGrid')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready():
	rect_position.y = _hide_y
	rect_size.x = _foreground.rect_size.x
	
	# TODO: Hacer algo así para los casos en los que se quiera que el inventario
	# inicie ya con unos objetos dentro.

	# Conectarse a señales del yo
	connect('mouse_entered', self, '_open')
	connect('mouse_exited', self, '_close')
	
	# Conectarse a las señales del papá de los inventarios
	I.connect('item_added', self, '_add_item')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func disable() -> void:
	_is_disabled = true
	$Tween.interpolate_property(
		self, 'rect_position:y',
		_hide_y, _hide_y - 3.5,
		0.3, Tween.TRANS_LINEAR, Tween.EASE_OUT
	)
	$Tween.start()


func enable() -> void:
	_is_disabled = false
	$Tween.interpolate_property(
		self, 'rect_position:y',
		_hide_y - 3.5, _hide_y,
		0.3, Tween.TRANS_SINE, Tween.EASE_OUT
	)
	$Tween.start()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _add_item(item: Item) -> void:
	_grid.add_child(item)
	
	item.connect('description_toggled', self, '_show_item_info')
	item.connect('selected', self, '_change_cursor')
	
	_open()
	yield(get_tree().create_timer(2.0), 'timeout')
	_close()

	I.emit_signal('item_add_done')


func _open() -> void:
	if not _is_disabled and rect_position.y != _hide_y: return
	$Tween.interpolate_property(
		self, 'rect_position:y',
		_hide_y if not _is_disabled else rect_position.y, 0.0,
		0.5, Tween.TRANS_EXPO, Tween.EASE_OUT
	)
	$Tween.start()


func _close() -> void:
	yield(get_tree(), 'idle_frame')
	if not _can_hide_inventory: return
	$Tween.interpolate_property(
		self, 'rect_position:y',
		0.0, _hide_y if not _is_disabled else _hide_y - 3.5,
		0.2, Tween.TRANS_SINE, Tween.EASE_IN
	)
	$Tween.start()


func _show_item_info(description := '') -> void:
	_can_hide_inventory = false if description else true


func _change_cursor(item: Item) -> void:
	I.set_active(item)
