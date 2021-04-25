extends CanvasLayer

onready var _dialog_text: DialogText = find_node('DialogText')
onready var _display_box: DisplayBox = find_node('DisplayBox')
onready var _inventory_container: InventoryContainer = find_node('InventoryContainer')
onready var _click_handler: Button = $MainContainer/ClickHandler
onready var _dialog_menu: DialogMenu = find_node('DialogMenu')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready():
	# --------------------------------------------------------------------------
	# Conectarse a eventos de los hijos
	# TODO: Algunos de estos realmente irán en el script de cada hijo
	_click_handler.connect('pressed', self, '_continue')
	_dialog_menu.connect('shown', self, '_hide_panels', [{blocking = false}])
	_display_box.connect('shown', self, '_hide_panels')
	_display_box.connect('hidden', self, '_show_panels')
	
	# Conectarse a eventos del universo digimon
	C.connect('character_spoke', self, '_show_dialog_text')
	G.connect('freed', self, '_show_panels')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _show_dialog_text(chr: Character, msg := '') -> void:
	_hide_panels()
	_dialog_text.play_text({
		text = msg,
		color = chr.text_color,
		position = Utils.get_screen_coords_for(chr),
		offset_y = chr.sprite.position.y
	})


func _hide_panels(props := { blocking = true }) -> void:
	if props.blocking:
		_click_handler.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		_click_handler.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if _inventory_container.is_disabled: return

	_inventory_container.disable()


func _show_panels() -> void:
	# TODO: Usar Tween para que se oculte y aparezca con jugo
	_click_handler.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_inventory_container.enable()


func _continue() -> void:
	_display_box.hide()
	_dialog_text.stop()
	G.emit_signal('continue_clicked')
