extends Control

const ToolbarButton := preload(
	PopochiuResources.GUI_TEMPLATES_FOLDER +
	"simple_click/components/settings_bar/buttons/settings_bar_button.gd"
)

@export var used_in_game := true
@export var always_visible := false
@export var hide_when_gui_is_blocked := false

var is_disabled := false

var _can_hide := true
var _is_hidden := true
var _is_mouse_hover := false

@onready var panel_container: PanelContainer = $PanelContainer
@onready var tween: Tween = null
@onready var box: BoxContainer = %Box
@onready var hidden_y := panel_container.position.y - (panel_container.size.y - 4)


#region Godot ######################################################################################
func _ready() -> void:
	if not always_visible:
		panel_container.position.y = hidden_y
	
	# Connect to child signals
	for b in box.get_children():
		(b as TextureButton).mouse_entered.connect(_disable_hide)
		(b as TextureButton).mouse_exited.connect(_enable_hide)
	
	# Connect to singletons signals
	if hide_when_gui_is_blocked:
		G.blocked.connect(_on_graphic_interface_blocked)
		G.unblocked.connect(_on_graphic_interface_unblocked)
	
	if not used_in_game:
		hide()
	
	set_process_input(not always_visible)
	
	panel_container.size.x = box.size.x


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion: return
	
	var rect := get_rect()
	
	if E.settings.scale_gui:
		rect = Rect2(
			panel_container.get_rect().position * E.scale,
			panel_container.get_rect().size * E.scale
		)
	
	if rect.has_point(get_global_mouse_position()):
		_is_mouse_hover = true
		Cursor.show_cursor("gui")
	elif _is_mouse_hover:
		_is_mouse_hover = false
		
		if D.current_dialog:
			Cursor.show_cursor("gui")
		elif G.gui.is_showing_dialog_line:
			Cursor.show_cursor("wait")
		else:
			Cursor.show_cursor("normal")
	
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


func _on_graphic_interface_blocked() -> void:
	set_process_input(false)
	hide()


func _on_graphic_interface_unblocked() -> void:
	set_process_input(true)
	show()


#endregion
