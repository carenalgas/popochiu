class_name PopochiuDialogText
extends Control
## Show dialogue texts char by char using a [RichTextLabel].
## 
## An invisible [Label] is used to calculate the width of the [RichTextLabel] node.

signal animation_finished
signal text_show_started
signal text_show_finished

const DFLT_SIZE := "dflt_size"
const DFLT_POSITION := "dflt_position"

@export var wrap_width := 200.0
@export var limit_margin := 4.0

var tween: Tween = null
var continue_icon_tween: Tween = null

var _secs_per_character := 1.0
var _is_waiting_input := false
var _auto_continue := false
var _dialog_pos := Vector2.ZERO
var _x_limit := 0.0
var _y_limit := 0.0

@onready var rich_text_label: RichTextLabel = %RichTextLabel
@onready var continue_icon: TextureProgressBar = %ContinueIcon
@onready var continue_icon_size := continue_icon.texture_progress.get_size()


#region Godot ######################################################################################
func _ready() -> void:
	# Set the default values
	rich_text_label.text = ""
	
	set_meta(DFLT_SIZE, rich_text_label.size)
	set_meta(DFLT_POSITION, rich_text_label.position)
	
	modulate.a = 0.0
	_secs_per_character = PopochiuUtils.e.text_speed
	_x_limit = PopochiuUtils.e.width / (
		PopochiuUtils.e.scale.x if PopochiuUtils.e.settings.scale_gui else 1.0
	)
	_y_limit = PopochiuUtils.e.height / (
		PopochiuUtils.e.scale.y if PopochiuUtils.e.settings.scale_gui else 1.0
	)
	
	# Connect to singletons events
	PopochiuUtils.e.text_speed_changed.connect(change_speed)
	PopochiuUtils.c.character_spoke.connect(_show_dialogue)
	
	continue_icon.hide()


func _input(event: InputEvent) -> void:
	if (
		not PopochiuUtils.get_click_or_touch_index(event) in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]
		or modulate.a == 0.0
	):
		return
	
	accept_event()
	if rich_text_label.visible_ratio == 1.0:
		disappear()
	else:
		stop()


#endregion

#region Public #####################################################################################
func play_text(props: Dictionary) -> void:
	var msg: String = PopochiuUtils.e.get_text(props.text)
	_is_waiting_input = false
	_dialog_pos = props.position
	
	if PopochiuConfig.should_talk_gibberish():
		msg = PopochiuUtils.d.create_gibberish(msg)
	
	# Call the virtual method that modifies the size of the RichTextLabel in case the dialog style
	# requires it.
	await _modify_size(msg, props.position)
	
	# Assign the text and align mode
	msg = "[color=%s]%s[/color]" % [props.color.to_html(), msg]
	_append_text(msg, props)
	
	if _secs_per_character > 0.0:
		# The text will appear with an animation
		if is_instance_valid(tween) and tween.is_running():
			tween.kill()
		
		tween = create_tween()
		tween.tween_property(
			rich_text_label, "visible_ratio",
			1,
			_secs_per_character * rich_text_label.get_total_character_count()
		).from(0.0)
		tween.finished.connect(_wait_input)
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
		if is_instance_valid(tween) and tween.is_running():
			tween.kill()
		
		rich_text_label.visible_ratio = 1.0
		_wait_input()


func disappear() -> void:
	if modulate.a == 0.0: return
	
	_auto_continue = false
	modulate.a = 0.0
	_is_waiting_input = false
	
	if is_instance_valid(tween) and tween.is_running():
		tween.kill()
	
	rich_text_label.clear()
	rich_text_label.text = ""
	_set_default_size()
	
	continue_icon.hide()
	continue_icon.modulate.a = 1.0
	
	if is_instance_valid(continue_icon_tween) and continue_icon_tween.is_running():
		continue_icon_tween.kill()
	
	set_process_input(false)
	text_show_finished.emit()
	PopochiuUtils.g.dialog_line_finished.emit()


func change_speed() -> void:
	_secs_per_character = PopochiuUtils.e.text_speed


#endregion

#region Private ####################################################################################
func _show_dialogue(chr: PopochiuCharacter, msg := "") -> void:
	if not visible: return
	
	play_text({
		text = msg,
		color = chr.text_color,
		position = PopochiuUtils.get_screen_coords_for(chr, chr.dialog_pos).floor() / (
			PopochiuUtils.e.scale if PopochiuUtils.e.settings.scale_gui else Vector2.ONE
		),
	})
	
	PopochiuUtils.g.dialog_line_started.emit()
	
	set_process_input(true)
	text_show_started.emit()


func _modify_size(_msg: String, _target_position: Vector2) -> void:
	await get_tree().process_frame


## Creates a RichTextLabel to calculate the resulting size of this node once the whole text is shown.
func _calculate_size(msg: String) -> Vector2:
	var rt := RichTextLabel.new()
	rt.add_theme_font_override("normal_font", get_theme_font("normal_font"))
	rt.bbcode_enabled = true
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.text = msg
	rt.size = get_meta(DFLT_SIZE)
	rich_text_label.add_child(rt)
	
	# Create a Label to check if the text exceeds the wrap_width
	var lbl := Label.new()
	lbl.add_theme_font_override("normal_font", get_theme_font("normal_font"))
	
	_set_default_label_size(lbl)
	
	lbl.text = rt.get_parsed_text()
	rich_text_label.add_child(lbl)
	
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
	else:
		# This node will have the width of the text
		_size.y = get_meta(DFLT_SIZE).y
	
	var characters_count := lbl.get_total_character_count()
	
	lbl.free()
	rt.free()
	
	return _size


func _set_default_label_size(lbl: Label) -> void:
	lbl.size = get_meta(DFLT_SIZE)


func _append_text(msg: String, _props: Dictionary) -> void:
	rich_text_label.append_text(msg)


func _wait_input() -> void:
	_is_waiting_input = true
	
	if is_instance_valid(tween) and tween.finished.is_connected(_wait_input):
		tween.finished.disconnect(_wait_input)
	
	if PopochiuUtils.e.auto_continue_after >= 0.0:
		_auto_continue = true
		await get_tree().create_timer(PopochiuUtils.e.auto_continue_after + 0.2).timeout
		
		if _auto_continue:
			_continue(true)
	else:
		_show_icon()


func _show_icon() -> void:
	if is_instance_valid(continue_icon_tween) and continue_icon_tween.is_running():
		continue_icon_tween.kill()
	
	continue_icon_tween = create_tween()
	
	if not PopochiuUtils.e.settings.auto_continue_text:
		# For manual continuation: make the icon jump
		continue_icon.value = 100.0
		continue_icon_tween.tween_property(
			continue_icon, "position:y", _get_icon_to_position(), 0.8
		).from(_get_icon_from_position()).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		continue_icon_tween.set_loops()
	else:
		# For automatic continuation: Make the icon appear as a progress bar indicating the time
		# players have to read before auto-continuing.
		continue_icon.value = 0.0
		continue_icon.position.y = size.y / 2.0
		
		continue_icon_tween.tween_property(
			continue_icon, "value",
			100.0, 3.0,
		).from_current().set_ease(Tween.EASE_OUT)
		continue_icon_tween.finished.connect(_continue)
	
	continue_icon_tween.pause()
	await get_tree().create_timer(0.2).timeout

	continue_icon_tween.play()
	continue_icon.show()


func _get_icon_from_position() -> float:
	return rich_text_label.size.y - continue_icon.size.y + 2.0


func _get_icon_to_position() -> float:
	return rich_text_label.size.y - continue_icon.size.y - 1.0


func _notify_completion() -> void:
	disappear()
	animation_finished.emit()


func _continue(forced_continue := false) -> void:
	if PopochiuUtils.e.settings.auto_continue_text or forced_continue:
		disappear()


func _set_default_size() -> void:
	rich_text_label.size = get_meta(DFLT_SIZE)


#endregion
