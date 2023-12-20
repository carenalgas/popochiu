extends PopochiuPopup

const SELECTION_COLOR := Color('edf171')
const OVERWRITE_COLOR := Color('c46c71')

var _current_slot: Button = null
var _slot_name := ''
var _prev_text := ''
var _slot := 0

@onready var slots: VBoxContainer = %Slots


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	super()
	
	btn_ok.disabled = true
	
	# Connect to singletons signals
	G.save_requested.connect(_show_save)
	G.load_requested.connect(_show_load)
	
	var saves: Dictionary = E.get_saves_descriptions()
	
	for btn in slots.get_children():
		(btn as Button).set_meta('has_save', false)
		
		if saves.has(btn.get_index() + 1):
			btn.text = saves[btn.get_index() + 1]
			(btn as Button).set_meta('has_save', true)
		else:
			btn.disabled = true
		
		btn.pressed.connect(_select_slot.bind(btn))


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _open() -> void:
	btn_ok.disabled = true
	_slot = 0
	
	if _current_slot:
		_current_slot.text = _prev_text
		_current_slot.button_pressed = false
		
		_current_slot = null
		_prev_text = ''


func _close() -> void:
	if not _slot: return
	
	if _slot_name:
		E.save_game(_slot, _slot_name)
	else:
		E.load_game(_slot)


func _on_ok() -> void:
	_slot = _current_slot.get_index() + 1
	
	if _slot_name:
		_prev_text = _current_slot.text
		_current_slot.set_meta('has_save', true)
	
	close()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func open_save() -> void:
	_show_save()


func open_load() -> void:
	_show_load()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _show_save(slot_text := "") -> void:
	lbl_title.text = 'Choose a slot to save the game'
	_slot_name = slot_text
	
	if _slot_name.is_empty():
		_slot_name = _format_date(Time.get_datetime_dict_from_system())
	
	for btn in slots.get_children():
		btn.disabled = false
	
	open()


func _show_load() -> void:
	lbl_title.text = 'Choose the slot to load'
	_slot_name = ''
	
	for btn in slots.get_children():
		btn.disabled = !(btn as Button).get_meta('has_save')
	
	open()


func _select_slot(btn: Button) -> void:
	if _slot_name:
		if _current_slot:
			_current_slot.text = _prev_text
			_current_slot.button_pressed = false
		
		_current_slot = btn
		_prev_text = _current_slot.text
		_current_slot.text = _slot_name
	else:
		if _current_slot:
			_current_slot.button_pressed = false
		
		_current_slot = btn
		_prev_text = _current_slot.text
	
	btn_ok.disabled = false


func _format_date(date: Dictionary) -> String:
	return '%d/%02d/%02d %02d:%02d:%02d' % [
		date.year, date.month, date.day, date.hour, date.minute, date.second
	]
