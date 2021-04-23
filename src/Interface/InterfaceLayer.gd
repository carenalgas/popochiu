extends CanvasLayer

var _is_inventory_hidden := false

onready var _info_bar: Label = find_node('InfoBar')
onready var _dialog_text: AnimatedRichText = find_node('DialogText')
onready var _display_box: Label = find_node('DisplayBox')
onready var _inventory_container: NinePatchRect = find_node('InventoryContainer')
onready var _click_handler: Button = $MainContainer/ClickHandler
onready var _dialog_menu: DialogMenu = find_node('DialogMenu')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready():
	_info_bar.text = ''

	_display_box.text = ''
	_display_box.hide()
	
	# --------------------------------------------------------------------------
	# Conectarse a eventos de los hijos
	# TODO: Algunos de estos realmente irán en el script de cada hijo
	_click_handler.connect('pressed', self, '_continue')
	_dialog_menu.connect('shown', self, '_hide_panels', [{blocking = false}])
	
	
	# Conectarse a eventos del universo digimon
	C.connect('character_spoke', self, '_show_dialog_text')
#	C.connect('character_moved', self, '_hide_interface_elements')
	G.connect('show_info_requested', self, '_update_info_bar')
	G.connect('show_box_requested', self, '_show_display_box')
	G.connect('freed', self, '_show_panels')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _update_info_bar(info := '') -> void:
	_info_bar.text = info


func _show_display_box(msg := '') -> void:
	_display_box.text = msg
	if msg:
		_hide_panels()
		_display_box.show()
	else:
		_show_panels()
		_display_box.hide()


func _show_dialog_text(chr: Character, msg := '') -> void:
	_hide_panels()
	_dialog_text.play_text({
		text = msg,
		color = chr.text_color,
		position = Utils.get_screen_coords_for(chr),
		offset_y = chr.sprite.position.y
	})


func _hide_interface_elements(chr: Character) -> void:
	# TODO: Afectar sólo al nodo que corresponda al personaje recibido
	_dialog_text.stop()
	_show_display_box()


func _hide_panels(props := { blocking = true }) -> void:
	if props.blocking:
		_click_handler.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		_click_handler.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if _is_inventory_hidden: return

	_is_inventory_hidden = true

	_inventory_container.disable()


func _show_panels() -> void:
	# TODO: Usar Tween para que se oculte y aparezca con jugo
	_is_inventory_hidden = false
	_click_handler.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_inventory_container.enable()


func _continue() -> void:
#	_info_bar.hide()
	_display_box.hide()
	_dialog_text.stop()
	G.emit_signal('continue_clicked')
