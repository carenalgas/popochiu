extends NinePatchRect

const CURSOR_TYPE := preload('res://addons/Popochiu/Engine/Cursor/Cursor.gd').Type
const ToolbarButton := preload('ToolbarButton.gd')

export(CURSOR_TYPE) var cursor
export var script_name := ''
export var used_in_game := true

var is_disabled := false

var _can_hide := true

onready var _btn_dialog_speed: ToolbarButton = find_node('BtnDialogSpeed')
onready var _btn_power: ToolbarButton = find_node('BtnPower')
onready var _grid: GridContainer = find_node('Grid')
onready var _hide_y := rect_position.y - (rect_size.y - 4)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	rect_position.y = _hide_y
	
	# Conectarse a señales del yo
	connect('mouse_entered', self, '_open')
	connect('mouse_exited', self, '_close')
	
	# Conectarse a señales de los hijos de la mamá
	for b in _grid.get_children():
		(b as TextureButton).connect('mouse_entered', self, '_disable_hide')
		(b as TextureButton).connect('mouse_exited', self, '_enable_hide')

	if not used_in_game:
		hide()


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


func _disable_hide() -> void:
	_can_hide = false


func _enable_hide() -> void:
	_can_hide = true
