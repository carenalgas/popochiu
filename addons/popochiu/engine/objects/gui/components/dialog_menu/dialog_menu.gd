class_name PopochiuDialogMenu
extends Control
@warning_ignore("return_value_discarded")
@warning_ignore("unused_signal")

signal shown

@export var option_scene: PackedScene
## Max height of the menu in pixels. If visible options make the menu to exceed this value, it will
## enable a vertical scroll bar.
@export var max_height := 49
@export_category("Option buttons")
@export var normal_font_color: Color = Color("706deb")
@export var normal_used_font_color: Color = Color("2e2c9b")
@export var hover_font_color: Color = Color("ffffff")
@export var hover_used_font_color: Color = Color("b2b2b2")
@export var pressed_font_color: Color = Color("a9ff9f")
@export var pressed_used_font_color: Color = Color("56ac4d")

var current_options := []

@onready var panel_container: PanelContainer = $PanelContainer
@onready var dialog_options_container: VBoxContainer = %DialogOptionsContainer


#region Godot ######################################################################################
func _ready() -> void:
	for child in dialog_options_container.get_children():
		child.queue_free()
	
	panel_container.custom_minimum_size = Vector2.ZERO
	
	# Connect to own signals
	gui_input.connect(_clicked)
	
	# Connect to autoloads signals
	PopochiuUtils.d.dialog_options_requested.connect(_create_options.bind(true))
	PopochiuUtils.d.inline_dialog_requested.connect(_create_inline_options)
	PopochiuUtils.d.dialog_finished.connect(remove_options)
	
	hide()


#endregion

#region Private ####################################################################################
func _clicked(event: InputEvent) -> void:
	if PopochiuUtils.get_click_or_touch_index(event) == MOUSE_BUTTON_LEFT:
		accept_event()


# Creates an Array of PopochiuDialogOption to show dialog tree options created
# during execution, (those that are created after calling D.show_inline_dialog)
func _create_inline_options(opts: Array) -> void:
	var tmp_opts := []
	for idx in opts.size():
		var new_opt: PopochiuDialogOption = PopochiuDialogOption.new()
		
		new_opt.id = str(idx)
		new_opt.text = opts[idx]
		
		tmp_opts.append(new_opt)

	_create_options(tmp_opts, true)


func _create_options(options := [], autoshow := false) -> void:
	remove_options()
	
	if options.is_empty():
		if not current_options.is_empty():
			show_options()
		return
	
	current_options = options.duplicate(true)
	
	for dialog_option: PopochiuDialogOption in options:
		var dialog_menu_option := option_scene.instantiate()
		dialog_menu_option.normal_color = normal_font_color
		dialog_menu_option.normal_used_color = normal_used_font_color
		dialog_menu_option.hover_color = hover_font_color
		dialog_menu_option.hover_used_color = hover_used_font_color
		dialog_menu_option.pressed_color = pressed_font_color
		dialog_menu_option.pressed_used_color = pressed_used_font_color
		dialog_options_container.add_child(dialog_menu_option)
		
		dialog_menu_option.option = dialog_option
		dialog_menu_option.pressed.connect(_on_option_clicked)
		
		if dialog_option.disabled or not dialog_option.visible:
			dialog_menu_option.hide()
		else:
			dialog_menu_option.show()
	
	if autoshow: show_options()
	await get_tree().create_timer(0.1).timeout
	
	# Fix: Height and position of the dialog menu was wrong when changing the amount of options to
	# show.
	var options_height := 0
	var visible_options := 0
	for opt in dialog_options_container.get_children():
		if not opt.visible: continue
		
		options_height += opt.size.y
		visible_options += 1
	
	options_height += (
		dialog_options_container.get_theme_constant("separation") * (visible_options - 1)
	)
	
	panel_container.size.y = min(options_height, max_height)
	panel_container.position.y = PopochiuUtils.e.height - panel_container.size.y


func remove_options(_dialog: PopochiuDialog = null) -> void:
	if not current_options.is_empty():
		current_options.clear()
		
		for btn in dialog_options_container.get_children():
			btn.queue_free()
	
	await get_tree().process_frame
	
	size.y = 0
	dialog_options_container.size.y = 0


func show_options() -> void:
	PopochiuUtils.g.block()
	PopochiuUtils.g.dialog_options_shown.emit()
	
	show()
	shown.emit()


func _on_option_clicked(opt: PopochiuDialogOption) -> void:
	PopochiuUtils.g.unblock()
	
	hide()
	PopochiuUtils.d.option_selected.emit(opt)


#endregion
