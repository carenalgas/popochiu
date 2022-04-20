extends Container

signal shown
signal hidden

const PopochiuDialogOption :=\
preload('res://addons/Popochiu/Engine/Objects/Dialog/PopochiuDialogOption.gd')

export var option_scene: PackedScene
export var default: Color = Color('5B6EE1')
export var used: Color = Color('3F3F74')
export var hover: Color = Color.white

var current_options := []


onready var _panel: Container = find_node('Panel')
onready var _options: Container = find_node('Options')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	connect('gui_input', self, '_clicked')
	
	# Conectarse a eventos de los evnetruchos
	D.connect('dialog_requested', self, '_create_options', [true])
	E.connect('inline_dialog_requested', self, '_create_dialog_options')
	D.connect('dialog_finished', self, 'remove_options')

	hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _clicked(event: InputEvent) -> void:
	var mouse_event: = event as InputEventMouseButton
	if mouse_event and mouse_event.button_index == BUTTON_LEFT \
		and mouse_event.pressed:
			pass


# Crea nodos de tipo PopochiuDialogOption para los casos en los que se muestran opciones
# de diálogo creadas en tiempo de ejecución, o sea, que no están en uno de los
# diálogos almacenados en la carpeta Dialogs.
func _create_dialog_options(opts: Array) -> void:
	var tmp_opts := []
	for idx in opts.size():
		var new_opt: PopochiuDialogOption = PopochiuDialogOption.new()
		var id := 'Opt%d' % (idx as int + 1)
		new_opt.id = id
		new_opt.text = opts[idx]
		
		tmp_opts.append(new_opt)

	_create_options(tmp_opts, true)


func _create_options(options := [], autoshow := false) -> void:
	remove_options()

	if options.empty():
		if not current_options.empty():
			show_options()
		return

	current_options = options.duplicate(true)

	for opt in options:
		var btn: Button = option_scene.instance() as Button
		var dialog_option: PopochiuDialogOption = opt

		btn.text = dialog_option.text
		btn.add_color_override('font_color', default)
		btn.add_color_override('font_color_hover', hover)
		
		if dialog_option.used:
			btn.add_color_override('font_color', used)

		btn.connect('pressed', self, '_on_option_clicked', [dialog_option])

		_options.add_child(btn)

		if not dialog_option.visible:
			btn.hide()
		else:
			btn.show()

	if autoshow: show_options()
	
	yield(get_tree(), 'idle_frame')

	_panel.rect_min_size.y = _options.rect_size.y


func remove_options() -> void:
	if not current_options.empty():
		current_options.clear()

		for btn in _options.get_children():
#			(btn as Button).call_deferred('queue_free')
			_options.remove_child(btn as Button)
#		hide()
	
	yield(get_tree(), 'idle_frame')

	_panel.rect_size.y = 0
	_options.rect_size.y = 0


func show_options() -> void:
	show()
	emit_signal('shown')


func _on_option_clicked(opt: PopochiuDialogOption) -> void:
	hide()
	opt.used = true
	D.emit_signal('option_selected', opt)
