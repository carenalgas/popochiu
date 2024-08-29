extends PopochiuHoverText

@export var follows_cursor := false

var _gui_width := 0.0
var _gui_height := 0.0
# Used to fix a warning shown by Godot related to the anchors of the node and changing its size
# during a _ready() execution
var _can_change_size := false


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	_gui_width = E.width
	_gui_height = E.height
	
	if E.settings.scale_gui:
		_gui_width /= E.scale.x
		_gui_height /= E.scale.y
	
	E.current_command = NineVerbCommands.Commands.WALK_TO
	
	set_process(follows_cursor)
	autowrap_mode = TextServer.AUTOWRAP_OFF if follows_cursor else TextServer.AUTOWRAP_WORD_SMART
	
	_show_text()
	E.ready.connect(set.bind("_can_change_size", true))


func _process(delta: float) -> void:
	position = get_viewport().get_mouse_position()
	
	if E.settings.scale_gui:
		position /= E.scale
	
	position -= size / 2.0
	position.y -= Cursor.get_cursor_height() / 2
	
	# Check viewport limits
	if position.x < 0.0:
		position.x = 0.0
	elif position.x + size.x > _gui_width:
		position.x = _gui_width - size.x
	
	if position.y < 0.0:
		position.y = 0.0
	elif position.y + size.y > _gui_height:
		position.y = _gui_height - size.y


#endregion

#region Private ####################################################################################
func _show_text(txt := "") -> void:
	text = ""
	
	if follows_cursor and _can_change_size:
		size = Vector2.ZERO
	
	if txt.is_empty():
		if (
			E.current_command == NineVerbCommands.Commands.WALK_TO
			and is_instance_valid(E.get_hovered())
		):
			super("%s %s" % [E.get_current_command_name(), E.get_hovered().description])
		elif E.current_command != NineVerbCommands.Commands.WALK_TO:
			super(E.get_current_command_name())
	elif not txt.is_empty() and not I.active:
		super("%s %s" % [E.get_current_command_name(), txt])
	elif I.active:
		super(txt)
	
	if follows_cursor and _can_change_size:
		size += Vector2.ONE * (Cursor.get_cursor_height() / 2)


#endregion
