class_name DialogMenu
extends Container

signal shown
signal hidden

var current_options := []

var _option: PackedScene = load('res://src/Interface/DialogMenu/DialogOption.tscn')

onready var _panel: Container = find_node('Panel')
onready var _options: Container = find_node('Options')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	connect('gui_input', self, '_clicked')
	
	# Conectarse a eventos de los evnetruchos
	G.connect('show_inline_dialog', self, '_create_options', [true])

	hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _clicked(event: InputEvent) -> void:
	var mouse_event: = event as InputEventMouseButton
	if mouse_event and mouse_event.button_index == BUTTON_LEFT \
		and mouse_event.pressed:
			prints('AaAaA')


func _create_options(options := [], autoshow := false) -> void:
	remove_options()

	if options.empty():
		if not current_options.empty():
			show_options()
		return

	current_options = options
	for opt in options:
		var btn: Button = _option.instance() as Button

		btn.text = opt
#		btn.connect('pressed', self, '_on_option_clicked', [opt])

		_options.add_child(btn)

#		if opt.has('show') and not opt.show:
#			opt.show = false
#			btn.hide()
#		else:
#			opt.show = true

	if autoshow: show_options()
	
	yield(get_tree(), 'idle_frame')

	_panel.rect_min_size.y = _options.rect_size.y
#	_panel.rect_position.y = Data.game_height - _options.rect_size.y
#
#
func remove_options() -> void:
	if not current_options.empty():
		current_options.clear()

		for btn in _options.get_children():
#			(btn as Button).call_deferred('queue_free')
			_options.remove_child(btn as Button)
#		hide()
	
	_panel.rect_size.y = 0
	_options.rect_size.y = 0
#
#
#func update_options(updates_cfg := {}) -> void:
#	if not updates_cfg.empty():
#		var idx := 0
#		for btn in get_children():
#			btn = (btn as Button)
#			var id := String(btn.get_index())
#			if updates_cfg.has(id):
#				if not updates_cfg[id]:
#					current_options[idx].show = false
#					btn.hide()
#				else:
#					current_options[idx].show = true
#					btn.show()
#			if btn.is_in_group('FocusGroup'):
#				btn.remove_from_group('FocusGroup')
#				btn.remove_from_group('DialogMenu')
#				guiBrain.gui_collect_focusgroup()
#			idx+= 1
#
#
func show_options() -> void:
	# Establecer cuál será la primera opción a seleccionar cuando se presione
	# una flecha del teclado

	show()
	emit_signal('shown')
#
#
#func _on_option_clicked(opt: Dictionary) -> void:
#	SectionEvent.dialog = false
#	hide()
#	DialogEvent.emit_signal('dialog_option_clicked', opt)
