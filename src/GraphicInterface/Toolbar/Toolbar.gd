class_name Toolbar
extends NinePatchRect

signal dialog_speed_changed(state)

export(Array, Texture) var dialog_states := []
export(Cursor.Type) var cursor
export var script_name := ''

var is_disabled := false

var _dialog_speed_state := 0
var _can_hide := true

onready var _btn_dialog: TextureButton = find_node('BtnDialog')
onready var _btn_power: TextureButton = find_node('BtnPower')
onready var _grid: GridContainer = find_node('Grid')
onready var _hide_y := rect_position.y - (rect_size.y - 4)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	rect_position.y = _hide_y
	
	# Conectarse a señales del yo
	connect('mouse_entered', self, '_open')
	connect('mouse_exited', self, '_close')
	
	# Conectarse a señales de los hijos de la mamá
	_btn_dialog.connect('pressed', self, '_change_dialog_speed')
	_btn_power.connect('pressed', self, '_quit_game')
	
	for b in _grid.get_children():
		(b as TextureButton).connect('mouse_entered', self, '_show_cursor', [b])
		(b as TextureButton).connect('mouse_exited', self, '_restore_cursor')

	# TODO: conectarse a señales del universo Chimpoko


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
	if not _can_hide: return
	$Tween.interpolate_property(
		self, 'rect_position:y',
		0.0, _hide_y if not is_disabled else _hide_y - 3.5,
		0.2, Tween.TRANS_SINE, Tween.EASE_IN
	)
	$Tween.start()


func _change_dialog_speed() -> void:
	_dialog_speed_state = wrapi(_dialog_speed_state + 1, 0, dialog_states.size())
	_btn_dialog.texture_normal = dialog_states[_dialog_speed_state]
	emit_signal('dialog_speed_changed', _dialog_speed_state)
	G.show_info(_btn_dialog.description)


func _quit_game() -> void:
	pass


func _show_cursor(btn: ToolbarButton) -> void:
	_can_hide = false
	Cursor.set_cursor(btn.cursor)
	G.show_info(btn.description)


func _restore_cursor() -> void:
	_can_hide = true
	Cursor.set_cursor()
	G.show_info()
