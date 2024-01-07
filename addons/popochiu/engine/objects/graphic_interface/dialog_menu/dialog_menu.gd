extends Container
@warning_ignore("return_value_discarded")
@warning_ignore("unused_signal")

signal shown

const PopochiuDialogOption :=\
preload('res://addons/popochiu/engine/objects/dialog/popochiu_dialog_option.gd')

@export var option_scene: PackedScene
@export var default: Color = Color('5B6EE1')
@export var used: Color = Color('3F3F74')
@export var hover: Color = Color.WHITE

var current_options := []

var _max_height := 0.0
var _visible_options := 0

@onready var _panel: Container = find_child('Panel')
@onready var _options: Container = find_child('Options')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	gui_input.connect(_clicked)
	
	# Connect to IDialog signals
	D.dialog_options_requested.connect(_create_options.bind(true))
	D.inline_dialog_requested.connect(_create_inline_options)
	D.dialog_finished.connect(remove_options)
	
	hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _clicked(event: InputEvent) -> void:
	var mouse_event: = event as InputEventMouseButton
	if mouse_event and mouse_event.button_index == MOUSE_BUTTON_LEFT \
		and mouse_event.pressed:
			pass


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

	for opt in options:
		var btn: Button = option_scene.instantiate() as Button
		var dialog_option: PopochiuDialogOption = opt

		btn.text = dialog_option.text
		btn.add_theme_color_override('font_color', default)
		btn.add_theme_color_override('font_hover_color', hover)
		
		if dialog_option.used and not dialog_option.always_on:
			btn.add_theme_color_override('font_color', used)
		
		btn.pressed.connect(_on_option_clicked.bind(dialog_option))

		_options.add_child(btn)

		if dialog_option.disabled or not dialog_option.visible:
			btn.hide()
		else:
			btn.show()
			_visible_options += 1
		
		
		if _max_height == 0.0:
			_max_height = btn.size.y * E.settings.max_dialog_options
			_max_height += E.settings.max_dialog_options - 1

	if autoshow: show_options()
	
	await get_tree().process_frame

	_panel.custom_minimum_size.y = min(_options.size.y, _max_height)


func remove_options(_dialog: PopochiuDialog = null) -> void:
	_visible_options = 0
	
	if not current_options.is_empty():
		current_options.clear()

		for btn in _options.get_children():
			_options.remove_child(btn as Button)
			(btn as Button).call_deferred('free')
	
	await get_tree().process_frame

	_panel.size.y = 0
	_options.size.y = 0


func show_options() -> void:
	show()
	shown.emit()


func _on_option_clicked(opt: PopochiuDialogOption) -> void:
	hide()
	D.option_selected.emit(opt)
