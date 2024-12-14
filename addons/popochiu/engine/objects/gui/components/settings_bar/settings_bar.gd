class_name PopochiuSettingsBar
extends Control

signal option_selected(option_name: String)

@export var used_in_game := true
@export var always_visible := false
@export var hide_when_gui_is_blocked := false
## Defines the height in pixels of the zone where moving the mouse in the top of the screen will
## make the bar to show. Note: This value will be affected by the Experimental Scale GUI checkbox
## in Project Settings > Popochiu > GUI.
@export var input_zone_height := 4

var is_disabled := false
var tween: Tween = null

var _can_hide := true
var _is_hidden := true
var _is_mouse_hover := false

@onready var panel_container: PanelContainer = $PanelContainer
@onready var box: BoxContainer = %Box
@onready var hidden_y := panel_container.position.y - panel_container.size.y


#region Godot ######################################################################################
func _ready() -> void:
	if not always_visible:
		panel_container.position.y = hidden_y
	
	# Connect to child signals
	for button: TextureButton in box.get_children():
		button.mouse_entered.connect(_disable_hide)
		button.mouse_exited.connect(_enable_hide)
		button.pressed.connect(_on_button_clicked.bind(button))
	
	# Connect to singletons signals
	if hide_when_gui_is_blocked:
		PopochiuUtils.g.blocked.connect(_on_gui_blocked)
		PopochiuUtils.g.unblocked.connect(_on_gui_unblocked)
	
	if not used_in_game:
		hide()
	
	set_process_input(not always_visible)
	
	panel_container.size.x = box.size.x


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion: return
	
	var rect := panel_container.get_rect()
	rect.size += Vector2(0.0, input_zone_height)
	if PopochiuUtils.e.settings.scale_gui:
		rect = Rect2(
			panel_container.get_rect().position * PopochiuUtils.e.scale,
			panel_container.get_rect().size * PopochiuUtils.e.scale
		)
	
	if rect.has_point(get_global_mouse_position()):
		_is_mouse_hover = true
		PopochiuUtils.cursor.show_cursor("gui")
	elif _is_mouse_hover:
		_is_mouse_hover = false
		
		if PopochiuUtils.d.current_dialog:
			PopochiuUtils.cursor.show_cursor("gui")
		elif PopochiuUtils.g.gui.is_showing_dialog_line:
			PopochiuUtils.cursor.show_cursor("wait")
		else:
			PopochiuUtils.cursor.show_cursor("normal")
	
	if _is_hidden and rect.has_point(get_global_mouse_position()):
		_open()
	elif not _is_hidden and not rect.has_point(get_global_mouse_position()):
		_close()


#endregion

#region Public #####################################################################################
func is_open() -> bool:
	return _is_hidden == false


#endregion

#region Private ####################################################################################
func _open() -> void:
	if always_visible: return
	if not is_disabled and panel_container.position.y != hidden_y: return
	
	if is_instance_valid(tween) and tween.is_running():
		tween.kill()
	
	tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel_container, "position:y", 0.0, 0.5).from(
		hidden_y if not is_disabled else panel_container.position.y
	)
	_is_hidden = false


func _close() -> void:
	if always_visible: return
	
	await get_tree().process_frame
	
	if not _can_hide: return
	
	if is_instance_valid(tween) and tween.is_running():
		tween.kill()
	
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(
		panel_container, "position:y", hidden_y if not is_disabled else hidden_y - 3.5, 0.2
	).from(0.0)
	_is_hidden = true


func _disable_hide() -> void:
	_can_hide = false


func _enable_hide() -> void:
	_can_hide = true


func _on_gui_blocked() -> void:
	set_process_input(false)
	hide()


func _on_gui_unblocked() -> void:
	set_process_input(true)
	show()


func _on_button_clicked(button: TextureButton) -> void:
	option_selected.emit(button.script_name)


#endregion
