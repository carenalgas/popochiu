extends RichTextLabel
# Show dialogue texts char by char using a RichTextLabel.
# An invisibla Label is used to calculate the width of the RichTextLabel node.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
# warning-ignore-all:unused_signal
# warning-ignore-all:return_value_discarded

signal animation_finished
signal text_show_started
signal text_show_finished

const DFLT_SIZE := "dflt_size"
const DFLT_POSITION := "dflt_position"

@export var wrap_width := 200.0
@export var limit_margin := 4.0
@export_enum("Above Character", "Portrait", "Caption") var used_when := 0

var _secs_per_character := 1.0
var _is_waiting_input := false
var _auto_continue := false
var _dialog_pos := Vector2.ZERO
var _x_limit := 0.0
var _y_limit := 0.0

@onready var _tween: Tween = null
@onready var _continue_icon: TextureProgressBar = $ContinueIcon
@onready var _continue_icon_tween: Tween = null


#region Godot ######################################################################################
func _ready() -> void:
	set_meta(DFLT_SIZE, size)
	set_meta(DFLT_POSITION, position)
	
	# Set the default values
	clear()
	
	modulate.a = 0.0
	_secs_per_character = E.text_speed
	_x_limit = E.width / (E.scale.x if E.settings.scale_gui else 1.0)
	_y_limit = E.height / (E.scale.y if E.settings.scale_gui else 1.0)
	
	_continue_icon.hide()
	
	# Connect to singletons events
	E.text_speed_changed.connect(change_speed)
	E.dialog_style_changed.connect(_on_dialog_style_changed)
	C.character_spoke.connect(_show_dialogue)
	
	_on_dialog_style_changed()


func _input(event: InputEvent) -> void:
	if not PopochiuUtils.is_click_or_touch_pressed(event) or modulate.a == 0.0:
		return
	
	get_viewport().set_input_as_handled()
	
	if PopochiuUtils.get_click_or_touch_index(event) != MOUSE_BUTTON_LEFT:
		return
	
	if visible_ratio == 1.0:
		disappear()
	else:
		stop()


#endregion

#region Public #####################################################################################
func play_text(props: Dictionary) -> void:
	var msg: String = E.get_text(props.text)
	_is_waiting_input = false
	_dialog_pos = props.position
	
	# ==== Calculate the size of the node ==========================================================
	# Create a RichTextLabel to calculate the resulting size of this node once
	# the whole text is shown
	var rt := RichTextLabel.new()
	rt.add_theme_font_override(
		"normal_font",
		get_theme_font("normal_font")
	)
	rt.bbcode_enabled = true
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.text = msg
	rt.size = get_meta(DFLT_SIZE)
	add_child(rt)
		
	# Create a Label to check if the text exceeds the wrap_width
	var lbl := Label.new()
	lbl.add_theme_font_override(
		"normal_font",
		get_theme_font("normal_font")
	)
	
	match E.current_dialog_style:
		0:
			lbl.size.y = get_meta(DFLT_SIZE).y
		_:
			lbl.size = get_meta(DFLT_SIZE)
	
	lbl.text = rt.get_parsed_text()
	add_child(lbl)
	
	rt.clear()
	rt.text = ""
	
	await get_tree().process_frame
	
	var _size := lbl.size
	
	if _size.x > wrap_width:
		# This node will have the width of the wrap_width
		_size.x = wrap_width
		rt.fit_content = true
		rt.size.x = _size.x
		rt.text = msg
		
		await get_tree().process_frame
		
		_size = rt.size
	elif _size.x < get_meta(DFLT_SIZE).x:
		# This node will have the minimum width
		_size.x = get_meta(DFLT_SIZE).x
	else:
		# This node will have the width of the text
		_size.y = get_meta(DFLT_SIZE).y
	
	var characters_count := lbl.get_total_character_count()
	
	lbl.free()
	rt.free()
	# ========================================================== Calculate the size of the node ====
	
	match E.current_dialog_style:
		0:
			# Define size and position (before calculating overflow)
			size = _size
			position = props.position - size / 2.0
			position.y -= size.y / 2.0
			
			# Calculate overflow and reposition
			if position.x < 0.0:
				position.x = limit_margin
			elif position.x + size.x > _x_limit:
				position.x = _x_limit - limit_margin - size.x
			if position.y < 0.0:
				position.y = limit_margin
			elif position.y + size.y > _y_limit:
				position.y = _y_limit - limit_margin - size.y
		2:
			# Define size and position (before calculating overflow)
			size.y = _size.y
			position.y = (
				get_meta(DFLT_POSITION).y - (_size.y - get_meta(DFLT_SIZE).y)
			)
	
	# Assign text and align mode
	push_color(props.color)
	
	match E.current_dialog_style:
		0:
			var center := floor(position.x + (size.x / 2))
			if center == props.position.x:
				append_text("[center]%s[/center]" % msg)
			elif center < props.position.x:
				append_text("[right]%s[/right]" % msg)
			else:
				append_text(msg)
		1:
			append_text(msg)
		2:
			text = "[center][color=%s]%s[/color][/center]" % [
				props.color.to_html(), msg
			]
	
	if _secs_per_character > 0.0:
		# The text will appear with an animation
		if is_instance_valid(_tween) and _tween.is_running():
			_tween.kill()
		
		_tween = create_tween()
		_tween.tween_property(
			self, "visible_ratio",
			1,
			_secs_per_character * get_total_character_count()
		).from(0.0)
		_tween.finished.connect(_wait_input)
	else:
		_wait_input()
	
	modulate.a = 1.0


func stop() ->void:
	if modulate.a == 0.0:
		return

	if _is_waiting_input:
		_notify_completion()
	else:
		# Skip tweens
		if is_instance_valid(_tween) and _tween.is_running():
			_tween.kill()
		
		visible_ratio = 1.0
		
		_wait_input()


func disappear() -> void:
	if modulate.a == 0.0: return
	
	_auto_continue = false
	modulate.a = 0.0
	_is_waiting_input = false
	
	if is_instance_valid(_tween) and _tween.is_running():
		_tween.kill()
	
	clear()
	text = ""
	
	_continue_icon.hide()
	_continue_icon.modulate.a = 1.0
	
	if is_instance_valid(_continue_icon_tween)\
	and _continue_icon_tween.is_running():
		_continue_icon_tween.kill()
	
	size = get_meta(DFLT_SIZE)
	
	set_process_input(false)
	text_show_finished.emit()
	G.dialog_line_finished.emit()


func change_speed() -> void:
	_secs_per_character = E.text_speed


#endregion

#region Private ####################################################################################
func _show_dialogue(chr: PopochiuCharacter, msg := "") -> void:
	if not visible: return
	
	play_text({
		text = msg,
		color = chr.text_color,
		position = PopochiuUtils.get_screen_coords_for(chr.dialog_pos).floor() / (
			E.scale if E.settings.scale_gui else Vector2.ONE
		),
	})
	
	G.dialog_line_started.emit()
	
	set_process_input(true)
	text_show_started.emit()


func _wait_input() -> void:
	_is_waiting_input = true
	
	if is_instance_valid(_tween) and _tween.finished.is_connected(_wait_input):
		_tween.finished.disconnect(_wait_input)
	
	if E.auto_continue_after >= 0.0:
		_auto_continue = true
		await get_tree().create_timer(E.auto_continue_after + 0.2).timeout
		
		if _auto_continue:
			_continue(true)
	else:
		_show_icon()


func _notify_completion() -> void:
	disappear()
	animation_finished.emit()


func _show_icon() -> void:
	if is_instance_valid(_continue_icon_tween)\
	and _continue_icon_tween.is_running():
		_continue_icon_tween.kill()
	
	_continue_icon_tween = create_tween()
#	_continue_icon.position.x = size.x
	
	if not E.settings.auto_continue_text:
		# For manual continuation: make the continue icon jump
		_continue_icon.value = 100.0
		
		var from_pos := 0.0
		var to_pos := 0.0
		
		match E.current_dialog_style:
			0:
				from_pos = size.y / 2.0 - 1.0
				to_pos = size.y / 2.0 + 3.0
			1, 2:
				to_pos = size.y - _continue_icon.size.y + 2.0
				from_pos = size.y - _continue_icon.size.y - 1.0
		
		_continue_icon_tween.tween_property(
			_continue_icon, "position:y", to_pos, 0.8
		).from(from_pos).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		_continue_icon_tween.set_loops()
	else:
		# For automatic continuation: Make the icon appear like a progress bar
		# the time players wil have to read befor auto-continuing
		_continue_icon.value = 0.0
		
		match E.current_dialog_style:
			0:
				_continue_icon.position.y = size.y / 2.0
		
		_continue_icon_tween.tween_property(
			_continue_icon, "value",
			100.0, 3.0,
		).from_current().set_ease(Tween.EASE_OUT)
		_continue_icon_tween.finished.connect(_continue)
	
	_continue_icon_tween.pause()
	
	await get_tree().create_timer(0.2).timeout

	_continue_icon_tween.play()
	_continue_icon.show()


func _continue(forced_continue := false) -> void:
	if E.settings.auto_continue_text or forced_continue:
		disappear()


func _on_dialog_style_changed() -> void:
	visible = E.current_dialog_style == used_when
	
	if E.current_dialog_style != 0 and E.current_dialog_style == used_when:
		wrap_width = size.x


#endregion
