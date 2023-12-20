extends PopochiuPopup

const DIALOG_LINE := preload('components/dialog_line.tscn')
const INTERACTION_LINE := preload('components/interaction_line.tscn')

@onready var lines_list: VBoxContainer = find_child('LinesList')
@onready var empty: Label = %Empty
@onready var lines_scroll: ScrollContainer = %LinesScroll


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	super()
	
	# Connect to singletons signals
	G.history_opened.connect(open)
	
	for c in lines_list.get_children():
		(c as Control).queue_free()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUALS ░░░░
func _open() -> void:
	if E.history.is_empty():
		empty.show()
		lines_scroll.hide()
	else:
		empty.hide()
		lines_scroll.show()
	
	for data in E.history:
		var lbl: RichTextLabel
		
		if data.has('character'):
			lbl = DIALOG_LINE.instantiate()
			lbl.text = '[color=%s]%s:[/color] %s' \
			% [
				(data.character as PopochiuCharacter).text_color.to_html(false),
				(data.character as PopochiuCharacter).description,
				data.text
			]
		else:
			lbl = INTERACTION_LINE.instantiate()
			lbl.text = '[color=edf171]%s[/color] [color=a9ff9f]%s[/color]'\
			% [data.action, data.target]
	
		lines_list.add_child(lbl)


func _close() -> void:
	for c in lines_list.get_children():
		(c as Control).queue_free()
