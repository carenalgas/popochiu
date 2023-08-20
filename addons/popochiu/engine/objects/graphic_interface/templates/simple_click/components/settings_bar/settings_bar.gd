extends PanelContainer

const ToolbarButton := preload('buttons/settings_bar_button.gd')

@export var script_name := ''
@export var used_in_game := true

var is_disabled := false

var _can_hide := true
var _is_hidden := true

@onready var _tween: Tween = null
@onready var _box: BoxContainer = find_child('Box')
@onready var _btn_dialog_speed: ToolbarButton = find_child('BtnDialogSpeed')
@onready var _btn_power: ToolbarButton = find_child('BtnQuit')
@onready var _hide_y := position.y - (size.y - 4)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	if not E.settings.toolbar_always_visible:
		position.y = _hide_y
	
	# Connect to child signals
	for b in _box.get_children():
		(b as TextureButton).mouse_entered.connect(_disable_hide)
		(b as TextureButton).mouse_exited.connect(_enable_hide)
	
	# Connect to singletons signals
	G.blocked.connect(_on_graphic_interface_blocked)
	G.unblocked.connect(_on_graphic_interface_unblocked)
	
	if not used_in_game:
		hide()
	
	set_process_input(not E.settings.toolbar_always_visible)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _is_hidden and get_rect().has_point(get_global_mouse_position()):
			_open()
		elif not _is_hidden\
		and not get_rect().has_point(get_global_mouse_position()):
			_close()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func is_open() -> bool:
	return _is_hidden == false


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _open() -> void:
	if E.settings.toolbar_always_visible: return
	if not is_disabled and position.y != _hide_y: return
	
	if is_instance_valid(_tween) and _tween.is_running():
		_tween.kill()
	
	_tween = create_tween()
	_tween.tween_property(self, 'position:y', 0.0, 0.5)\
	.from(_hide_y if not is_disabled else position.y)\
	.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	
	Cursor.show_cursor("gui")
	
	_is_hidden = false


func _close() -> void:
	if E.settings.toolbar_always_visible: return
	
	await get_tree().process_frame
	
	if not _can_hide: return
	
	if is_instance_valid(_tween) and _tween.is_running():
		_tween.kill()
	
	_tween = create_tween()
	_tween.tween_property(
		self, 'position:y',
		_hide_y if not is_disabled else _hide_y - 3.5,
		0.2
	).from(0.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	Cursor.show_cursor()
	
	_is_hidden = true


func _disable_hide() -> void:
	_can_hide = false


func _enable_hide() -> void:
	_can_hide = true


func _on_graphic_interface_blocked() -> void:
	set_process_input(false)
	# TODO: Should the component hide itself when the GUI is blocked?


func _on_graphic_interface_unblocked() -> void:
	set_process_input(true)
