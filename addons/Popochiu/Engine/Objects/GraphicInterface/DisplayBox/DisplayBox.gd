extends RichTextLabel
# Show a text in the form of GUI. Can be used to show game (or narrator)
# messages.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
# warning-ignore-all:unused_signal
# warning-ignore-all:return_value_discarded

signal shown
signal hidden

const DFLT_SIZE := 'dflt_size'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	G.connect('show_box_requested', self, '_show_box')
	set_meta(DFLT_SIZE, rect_size)
	
	close()


func _draw() -> void:
	rect_position = get_parent().rect_size / 2.0 - rect_size / 2.0


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PULBIC ░░░░
func appear() -> void:
	show()


func close() -> void:
	clear()
	rect_size = get_meta(DFLT_SIZE)
	
	hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _show_box(msg := '') -> void:
	rect_size = get_meta(DFLT_SIZE)
	
	# ==== Calculate the width of the node =====================================
	var rt := RichTextLabel.new()
	var lbl := Label.new()
	rt.append_bbcode(msg)
	lbl.text = rt.text
	add_child(lbl)
	var size := lbl.rect_size
	if size.x > get_meta(DFLT_SIZE).x:
		size.x = get_meta(DFLT_SIZE).x - 16.0
	lbl.free()
	rt.free()
	# ===================================== Calculate the width of the node ====
	
	append_bbcode('[center]%s[/center]' % msg)
	rect_size = Vector2(size.x + 16.0, get_meta(DFLT_SIZE).y)
	
	if msg:
		appear()
	else:
		close()
