@tool
extends PopochiuPopup

signal slot_selected

const SELECTION_COLOR := Color("edf171")
const OVERWRITE_COLOR := Color("c46c71")

var _current_slot: Button = null
var _slot_name := ""
var _prev_text := ""
var _slot := 0

@onready var slots: VBoxContainer = %Slots


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	if Engine.is_editor_hint(): return
	
	btn_ok.disabled = true
	
	var saves: Dictionary = PopochiuUtils.e.get_saves_descriptions()
	
	for btn: Button in slots.get_children():
		btn.set_meta("has_save", false)
		
		if saves.has(btn.get_index() + 1):
			btn.text = saves[btn.get_index() + 1]
			btn.set_meta("has_save", true)
		else:
			btn.disabled = true
		
		btn.pressed.connect(_select_slot.bind(btn))


#endregion

#region Virtual ####################################################################################
func _open() -> void:
	btn_ok.disabled = true
	_slot = 0
	
	if _current_slot:
		_current_slot.text = _prev_text
		_current_slot.button_pressed = false
		
		_current_slot = null
		_prev_text = ""


func _close() -> void:
	if not _slot: return
	
	slot_selected.emit()
	
	if _slot_name:
		PopochiuUtils.e.save_game(_slot, _slot_name)
	else:
		PopochiuUtils.e.load_game(_slot)


func _on_ok() -> void:
	_slot = _current_slot.get_index() + 1
	
	if _slot_name:
		_prev_text = _current_slot.text
		_current_slot.set_meta("has_save", true)
	
#endregion

#region Public #####################################################################################
func open_save() -> void:
	_show_save()


func open_load() -> void:
	_show_load()


#endregion

#region Private ####################################################################################
func _show_save(slot_text := "") -> void:
	lbl_title.text = "Choose a slot to save the game"
	_slot_name = slot_text
	
	if _slot_name.is_empty():
		_slot_name = _format_date(Time.get_datetime_dict_from_system())
	
	for btn in slots.get_children():
		btn.disabled = false
	
	open()


func _show_load() -> void:
	lbl_title.text = "Choose the slot to load"
	_slot_name = ""
	
	for btn in slots.get_children():
		btn.disabled = !(btn as Button).get_meta("has_save")
	
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
	return "%d/%02d/%02d %02d:%02d:%02d" % [
		date.year, date.month, date.day, date.hour, date.minute, date.second
	]


#endregion
