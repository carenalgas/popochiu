extends CanvasLayer
# Handles the Graphic Interface (a.k.a. UI)
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
# warning-ignore-all:return_value_discarded

const DialogText := preload('dialog_text/dialog_text.gd')
const DisplayBox := preload('display_box/display_box.gd')
const Inventory := preload('inventory/inventory.gd')
const DialogMenu := preload('dialog_menu/dialog_menu.gd')
const Toolbar := preload('toolbar/toolbar.gd')
const History := preload('history/history.gd')

@onready var _info_bar: Label = find_child('InfoBar')
@onready var _dialog_text: DialogText = find_child('DialogText')
@onready var _display_box: DisplayBox = find_child('DisplayBox')
@onready var _inventory: Inventory = find_child('Inventory')
@onready var _click_handler: Button = $MainContainer/ClickHandler
@onready var _dialog_menu: DialogMenu = find_child('DialogMenu')
@onready var _toolbar: Toolbar = find_child('Toolbar')
@onready var _history: History = find_child('History')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready():
	# Connect to children signals
	# TODO: Some of this could be in their own script
	_click_handler.pressed.connect(_continue)
	_dialog_menu.shown.connect(_disable_panels.bind({ blocking = false }))
	_display_box.shown.connect(_enable_panels)
	
	# Connect to singleton signals
	G.blocked.connect(_disable_panels)
	G.freed.connect(_enable_panels)
	G.interface_hidden.connect(_hide_panels)
	G.interface_shown.connect(_show_panels)
	G.continue_requested.connect(_continue)
	
	if E.settings.scale_gui:
		$MainContainer.scale = E.scale


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
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
	_dialog_text.disappear()
	
	_info_bar.show()
	_inventory.show()
	_toolbar.show()
	
	_inventory.enable()
	_toolbar.enable()


func _continue() -> void:
	if _dialog_text.visible_ratio == 1.0:
		_dialog_text.disappear()
		_display_box.close()
		
		G.continue_clicked.emit()
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
