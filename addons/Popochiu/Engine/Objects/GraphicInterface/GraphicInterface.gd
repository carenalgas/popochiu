extends CanvasLayer
# Handles the Graphic Interface (a.k.a. UI)
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
# warning-ignore-all:return_value_discarded

const DialogText := preload('DialogText/DialogText.gd')
const DisplayBox := preload('DisplayBox/DisplayBox.gd')
const Inventory := preload('Inventory/Inventory.gd')
const DialogMenu := preload('DialogMenu/DialogMenu.gd')
const Toolbar := preload('Toolbar/Toolbar.gd')
const History := preload('History/History.gd')

onready var _info_bar: Label = find_node('InfoBar')
onready var _dialog_text: DialogText = find_node('DialogText')
onready var _display_box: DisplayBox = find_node('DisplayBox')
onready var _inventory: Inventory = find_node('Inventory')
onready var _click_handler: Button = $MainContainer/ClickHandler
onready var _dialog_menu: DialogMenu = find_node('DialogMenu')
onready var _toolbar: Toolbar = find_node('Toolbar')
onready var _history: History = find_node('History')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready():
	# Connect to children signals
	# TODO: Some of this could be in their own script
	_click_handler.connect('pressed', self, '_continue')
	_dialog_menu.connect('shown', self, '_disable_panels', [{ blocking = false }])
	_display_box.connect('shown', self, '_disable_panels')
	_display_box.connect('hidden', self, '_enable_panels')
	
	# Connect to singleton signals
	C.connect('character_spoke', self, '_show_dialog_text')
	G.connect('blocked', self, '_disable_panels')
	G.connect('freed', self, '_enable_panels')
	G.connect('interface_hidden', self, '_hide_panels')
	G.connect('interface_shown', self, '_show_panels')
	
	if E.settings.scale_gui:
		$MainContainer.rect_scale = E.scale


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _show_dialog_text(chr: PopochiuCharacter, msg := '') -> void:
	_disable_panels()
	
	E.add_history({
		character = chr.description,
		text = msg
	})


func _disable_panels(props := { blocking = true }) -> void:
	if props.blocking:
		_click_handler.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		_click_handler.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_info_bar.hide()
	
	if _inventory.is_disabled: return

	_inventory.disable()
	_toolbar.disable()


func _enable_panels() -> void:
	# TODO: Add juice with a Tween \ ( ;) )/
	_click_handler.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_display_box.close()
	_dialog_text.hide()
	
	_info_bar.show()
	_inventory.show()
	_toolbar.show()
	
	_inventory.enable()
	_toolbar.enable()


func _continue() -> void:
	if _dialog_text.percent_visible == 1.0:
		_dialog_text.hide()
		_display_box.close()
		
		G.emit_signal('continue_clicked')
	else:
		_dialog_text.stop()


func _hide_panels() -> void:
	_inventory.hide()
	_info_bar.hide()
	_toolbar.hide()


func _show_panels() -> void:
	_inventory.show()
	_info_bar.show()
	_toolbar.show()
