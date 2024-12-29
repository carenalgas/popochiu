extends Control
## Show a text in the form of GUI. Can be used to show game (or narrator)
## messages.

const DFLT_SIZE := "dflt_size"

# Used to fix a warning shown by Godot related to the anchors of the node and changing its size
# during a _ready() execution
var _can_change_size := false

@onready var rich_text_label: RichTextLabel = %RichTextLabel


#region Godot ######################################################################################
func _ready() -> void:
	set_meta(DFLT_SIZE, rich_text_label.size)
	
	# Connect to singletons signals
	PopochiuUtils.g.system_text_shown.connect(_show_text)
	PopochiuUtils.e.ready.connect(set.bind("_can_change_size", true))
	
	close()


func _draw() -> void:
	rich_text_label.position = get_parent().size / 2.0 - (rich_text_label.size / 2.0)


func _input(event: InputEvent) -> void:
	if event.is_action_released("popochiu-skip"):
		close.call_deferred()
	
	if not PopochiuUtils.is_click_or_touch_pressed(event) or not visible:
		return
	
	accept_event()
	if PopochiuUtils.get_click_or_touch_index(event) == MOUSE_BUTTON_LEFT:
		close()


#endregion

#region Public #####################################################################################
func appear() -> void:
	show()
	set_process_input(true)


func close() -> void:
	set_process_input(false)
	
	rich_text_label.clear()
	rich_text_label.text = ""
	
	if _can_change_size:
		rich_text_label.size = get_meta(DFLT_SIZE)
	
	hide()
	PopochiuUtils.g.system_text_hidden.emit()


#endregion

#region Private ####################################################################################
func _show_text(msg := "") -> void:
	if PopochiuUtils.e.cutscene_skipped:
		close.call_deferred()
		return
	
	rich_text_label.clear()
	rich_text_label.text = ""
	rich_text_label.size = get_meta(DFLT_SIZE)
	rich_text_label.append_text("[center]%s[/center]" % msg)
	
	if msg:
		appear()
	else:
		close()


#endregion
