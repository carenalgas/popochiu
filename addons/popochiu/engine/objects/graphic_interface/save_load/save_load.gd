extends PanelContainer
@warning_ignore("return_value_discarded")

const SELECTION_COLOR := Color('edf171')
const OVERWRITE_COLOR := Color('c46c71')

var _current_slot: Button = null
var _date := ''
var _prev_text := ''
var _slot := 0

@onready var _dialog: PanelContainer = $SaveLoadDialog
@onready var _label: Label = %Title
@onready var _slots: VBoxContainer = %Slots
@onready var _ok: Button = %Ok
@onready var _cancel: Button = %Close


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	_ok.disabled = true
	
#	_dialog.confirmed.connect(_close)
#	_dialog.close_requested.connect(_close)
#	_dialog.get_cancel_button().pressed.connect(_close)
	_ok.pressed.connect(_confirmed)
	_cancel.pressed.connect(_close)
	
	var saves: Dictionary = E.get_saves_descriptions()
	
	for btn in _slots.get_children():
		(btn as Button).set_meta('has_save', false)
		
		if saves.has(btn.get_index() + 1):
			btn.text = saves[btn.get_index() + 1]
			(btn as Button).set_meta('has_save', true)
		else:
			btn.disabled = true
		
		btn.pressed.connect(_select_slot.bind(btn))
	
	G.save_requested.connect(_show_save)
	G.load_requested.connect(_show_load)
	
	hide()
#	_dialog.hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _show_save(date: String) -> void:
#	_dialog.title = 'Save'
	_label.text = 'Choose a slot to save the game'
	_date = date
	
	for btn in _slots.get_children():
		btn.disabled = false
	
	_show()


func _show_load() -> void:
#	_dialog.title = 'Load'
	_label.text = 'Choose the slot to load'
	_date = ''
	
	for btn in _slots.get_children():
		btn.disabled = !(btn as Button).get_meta('has_save')
	
	_show()


func _show() -> void:
	_ok.disabled = true
	_slot = 0
	
	if _current_slot:
		_current_slot.text = _prev_text
		_current_slot.button_pressed = false
		
		_current_slot = null
		_prev_text = ''
	
	if E.settings.scale_gui:
		scale = Vector2.ONE * E.scale
#		_dialog.size = Vector2.ONE * E.scale
	
#	_dialog.popup_centered(Vector2(240.0, 120.0))
	_cancel.grab_focus()
	
	G.blocked.emit({ blocking = false })
	Cursor.set_cursor(Cursor.Type.USE)
	Cursor.block()
	
	show()


func _close() -> void:
	G.done()
	Cursor.unlock()
	
	hide()
	
	if not _slot: return
	
	if _date:
		E.save_game(_slot, _date)
	else:
		E.load_game(_slot)


func _select_slot(btn: Button) -> void:
	if _date:
		if _current_slot:
			_current_slot.text = _prev_text
			_current_slot.button_pressed = false
		
		_current_slot = btn
		_prev_text = _current_slot.text
		_current_slot.text = _date
	else:
		if _current_slot:
			_current_slot.button_pressed = false
		
		_current_slot = btn
		_prev_text = _current_slot.text
	
	_ok.disabled = false


func _confirmed() -> void:
	_slot = _current_slot.get_index() + 1
	
	if _date:
		_prev_text = _current_slot.text
		_current_slot.set_meta('has_save', true)
	
	_close()
