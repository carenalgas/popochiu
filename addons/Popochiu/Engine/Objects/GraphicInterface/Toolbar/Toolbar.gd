extends PanelContainer
# warning-ignore-all:return_value_discarded

const ToolbarButton := preload('ToolbarButton.gd')

export var script_name := ''
export var used_in_game := true

var is_disabled := false

var _can_hide := true

onready var _box: BoxContainer = find_node('Box')
onready var _btn_dialog_speed: ToolbarButton = find_node('BtnDialogSpeed')
onready var _btn_power: ToolbarButton = find_node('BtnPower')
onready var _hide_y := rect_position.y - (rect_size.y - 4)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	if not E.settings.toolbar_always_visible:
		rect_position.y = _hide_y
	
		# Connect to self signals
		connect('mouse_entered', self, '_open')
		connect('mouse_exited', self, '_close')
	
	# Conectarse a señales de los hijos de la mamá
	for b in _box.get_children():
		(b as TextureButton).connect('mouse_entered', self, '_disable_hide')
		(b as TextureButton).connect('mouse_exited', self, '_enable_hide')

	if not used_in_game:
		hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func disable() -> void:
	is_disabled = true
	
	if E.settings.toolbar_always_visible:
		hide()
		return
	
	$Tween.interpolate_property(
		self, 'rect_position:y',
		_hide_y, _hide_y - 3.5,
		0.3, Tween.TRANS_LINEAR, Tween.EASE_OUT
	)
	$Tween.start()


func enable() -> void:
	is_disabled = false
	
	if E.settings.toolbar_always_visible:
		show()
		return
	
	$Tween.interpolate_property(
		self, 'rect_position:y',
		_hide_y - 3.5, _hide_y,
		0.3, Tween.TRANS_SINE, Tween.EASE_OUT
	)
	$Tween.start()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _open() -> void:
	if E.settings.toolbar_always_visible: return
	if not is_disabled and rect_position.y != _hide_y: return
	
	$Tween.interpolate_property(
		self, 'rect_position:y',
		_hide_y if not is_disabled else rect_position.y, 0.0,
		0.5, Tween.TRANS_EXPO, Tween.EASE_OUT
	)
	$Tween.start()


func _close() -> void:
	if E.settings.toolbar_always_visible: return
	
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
