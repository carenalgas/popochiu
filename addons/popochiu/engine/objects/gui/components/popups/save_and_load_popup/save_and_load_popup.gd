@tool
extends PopochiuPopup

signal slot_selected

const SELECTION_COLOR := Color("edf171")
const OVERWRITE_COLOR := Color("c46c71")

var _current_slot: TextureButton = null
var _slot_name := ""
var _prev_text := ""
var _slot := 0

@onready var slots: HBoxContainer = %Slots

const SAVE_SCREENSHOT_PATH := "user://screenshot_%d.png"


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	if Engine.is_editor_hint(): return
	
	btn_ok.disabled = true
	
	var saves: Dictionary = E.get_saves_descriptions()
	
	for btn_loop: VBoxContainer in slots.get_children():
		var btn: TextureButton = btn_loop.get_node("BtnSlot")
		btn.set_meta("has_save", false)
		
		if saves.has(btn_loop.get_index() + 1):
			btn_loop.get_node("Label").text = saves[btn.get_index() + 1]
			btn.set_meta("has_save", true)
			

			
		else:
			btn.disabled = true
			btn_loop.get_node("Label").text = "Empty Slot"
			
		btn.pressed.connect(_select_slot.bind(btn))

#endregion

#region Virtual ####################################################################################
func _open() -> void:
	btn_ok.disabled = true
	_slot = 0
	
	if _current_slot:
		_current_slot.get_node("../Label").text = _prev_text
		_current_slot.button_pressed = false
		
		_current_slot = null
		_prev_text = ""


func _close() -> void:
	if not _slot: return
	
	slot_selected.emit()
	
	if _slot_name:
		E.save_game(_slot, _slot_name)
	else:
		E.load_game(_slot)


func _on_ok() -> void:
	_slot = _current_slot.get_node("..").get_index() + 1
	
	if _slot_name:
		_prev_text = _current_slot.get_node("../Label").text
		_current_slot.set_meta("has_save", true)
	
#	close()


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
	
	for btn_loop in slots.get_children():
		var btn: TextureButton = btn_loop.get_node("BtnSlot")
		btn.disabled = false
	
	open()


func _show_load() -> void:
	lbl_title.text = "Choose the slot to load"
	_slot_name = ""
	
	var counter := 1
	for btn_loop in slots.get_children():
		var btn: TextureButton = btn_loop.get_node("BtnSlot")
		btn.disabled = !(btn as TextureButton).get_meta("has_save")
		var save_screenshot_name := SAVE_SCREENSHOT_PATH % (btn_loop.get_index() + 1)
		#var save_screenshot_name := SAVE_SCREENSHOT_PATH % 1
		if FileAccess.file_exists(save_screenshot_name):
			var screenshot_opened := FileAccess.open(save_screenshot_name, FileAccess.READ)
			if not screenshot_opened:
				PopochiuUtils.print_error(
					"Could not open the file %s. Error code: %s" % [
						save_screenshot_name, screenshot_opened.get_open_error()
					]
				)
				continue
			var file:FileAccess = FileAccess.open(save_screenshot_name, FileAccess.READ)
			if FileAccess.get_open_error() != OK:
				print(str("Could not load screenshot image : ",save_screenshot_name))
				continue			
			var img_buffer = file.get_buffer(file.get_length())
			var savegame_img = Image.new()
			var load_error := savegame_img.load_png_from_buffer(img_buffer)
			if load_error != OK:
				print(str("Error loading image : ",save_screenshot_name," with error: ",load_error))
				return			
			var savegame_texture = ImageTexture.create_from_image(savegame_img)
			btn_loop.get_node("BtnSlot").texture_normal = savegame_texture
	open()


func _select_slot(btn: TextureButton) -> void:
	if _slot_name:
		if _current_slot:
			_current_slot.get_node("../Label").text = _prev_text
			_current_slot.button_pressed = false
		
		_current_slot = btn
		_prev_text = _current_slot.get_node("../Label").text
		_current_slot.get_node("../Label").text = _slot_name
	else:
		if _current_slot:
			_current_slot.button_pressed = false
		
		_current_slot = btn
		_prev_text = _current_slot.get_node("../Label").text
	
	btn_ok.disabled = false


func _format_date(date: Dictionary) -> String:
	return "%d/%02d/%02d %02d:%02d:%02d" % [
		date.year, date.month, date.day, date.hour, date.minute, date.second
	]


#endregion
