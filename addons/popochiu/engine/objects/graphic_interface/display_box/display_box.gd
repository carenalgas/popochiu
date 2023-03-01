extends RichTextLabel
# Show a text in the form of GUI. Can be used to show game (or narrator)
# messages.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
# warning-ignore-all:unused_signal
# warning-ignore-all:return_value_discarded

signal shown

const DFLT_SIZE := 'dflt_size'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	G.show_box_requested.connect(_show_box)
	set_meta(DFLT_SIZE, size)
	
	close()


func _draw() -> void:
	position = get_parent().size / 2.0 - size / 2.0


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PULBIC ░░░░
func appear() -> void:
	show()


func close() -> void:
	clear()
	size = get_meta(DFLT_SIZE)
	
	hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _show_box(msg := '') -> void:
	size = get_meta(DFLT_SIZE)
	
	# ==== Calculate the width of the node =====================================
	var rt := RichTextLabel.new()
	var lbl := Label.new()
	rt.append_text(msg)
	lbl.text = rt.text
	add_child(lbl)
	var size := lbl.size
	if size.x > get_meta(DFLT_SIZE).x:
		size.x = get_meta(DFLT_SIZE).x - 16.0
	lbl.free()
	rt.free()
	# ===================================== Calculate the width of the node ====
	
	append_text('[center]%s[/center]' % msg)
	size = Vector2(size.x + 16.0, get_meta(DFLT_SIZE).y)
	
	if msg:
		appear()
	else:
		close()
