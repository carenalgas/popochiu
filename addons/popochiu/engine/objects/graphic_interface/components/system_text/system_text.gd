extends RichTextLabel
## Show a text in the form of GUI. Can be used to show game (or narrator)
## messages.

signal shown

const DFLT_SIZE := 'dflt_size'


#region Godot ######################################################################################
func _ready() -> void:
	set_meta(DFLT_SIZE, size)
	
	# Connect to singletons signals
	G.system_text_shown.connect(_show_text)
	
	close()


func _draw() -> void:
	position = get_parent().size / 2.0 - size / 2.0


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not visible:
		return
	
	var e: InputEventMouseButton = event
	
	get_viewport().set_input_as_handled()
	
	if e.is_pressed() and e.button_index == MOUSE_BUTTON_LEFT:
		close()


#endregion

#region Public #####################################################################################
func appear() -> void:
	show()
	set_process_input(true)


func close() -> void:
	set_process_input(false)
	
	clear()
	text = ""
	size = get_meta(DFLT_SIZE)
	
	hide()
	G.system_text_hidden.emit()


#endregion

#region Private ####################################################################################
func _show_text(msg := '') -> void:
	clear()
	text = ""
	size = get_meta(DFLT_SIZE)
	
	# ==== Calculate the width of the node =========================================================
	var rt := RichTextLabel.new()
	var lbl := Label.new()
	rt.append_text(msg)
	lbl.text = rt.text
	add_child(lbl)
	
	var lbl_size := lbl.size
	if lbl_size.x > get_meta(DFLT_SIZE).x:
		lbl_size.x = get_meta(DFLT_SIZE).x - 16.0
	
	lbl.free()
	rt.free()
	# ========================================================= Calculate the width of the node ====
	
	append_text('[center]%s[/center]' % msg)
	
	if msg:
		appear()
	else:
		close()


#endregion
