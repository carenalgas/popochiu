extends RichTextLabel
# Show dialogue texts char by char using a RichTextLabel.
# An invisibla Label is used to calculate the width of the RichTextLabel node.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
# warning-ignore-all:unused_signal
# warning-ignore-all:return_value_discarded

signal animation_finished

const DFLT_SIZE := 'dflt_size'

export var wrap_width := 200.0
export var limit_margin := 4.0

var _secs_per_character := 1.0
var _is_waiting_input := false
var _auto_continue := false
var _dialog_pos := Vector2.ZERO
var _x_limit := 0.0
var _y_limit := 0.0

onready var _tween: Tween = $Tween
onready var _continue_icon: TextureProgress = find_node('ContinueIcon')
onready var _continue_icon_tween: Tween = _continue_icon.get_node('Tween')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	set_meta(DFLT_SIZE, rect_size)
	
	# Set the default values
	clear()
	
	modulate.a = 0.0
	_secs_per_character = E.current_text_speed
	_x_limit = E.width / (E.scale.x if E.settings.scale_gui else 1.0)
	_y_limit = E.height / (E.scale.y if E.settings.scale_gui else 1.0)
	
	_continue_icon.hide()
	
	# Conectarse a señales de los hijos
	_tween.connect('tween_all_completed', self, '_wait_input')
	_continue_icon_tween.connect('tween_all_completed', self, '_continue')
	
	# Conectarse a eventos del universo Chimpoko
	E.connect('text_speed_changed', self, 'change_speed')
	C.connect('character_spoke', self, '_show_dialogue')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func play_text(props: Dictionary) -> void:
	var msg: String = E.get_text(props.text)
	_is_waiting_input = false
	_dialog_pos = props.position
	
	# ==== Calculate the width of the node =====================================
	var rt := RichTextLabel.new()
	var lbl := Label.new()
	rt.append_bbcode(msg)
	lbl.text = rt.text
	add_child(lbl)
	var size := lbl.rect_size
	if size.x > wrap_width:
		size.x = wrap_width
		rt.fit_content_height = true
		rt.rect_size = Vector2(size.x, 0.0)
		add_child(rt)
		size.y = rt.get_content_height()
	elif size.x < get_meta(DFLT_SIZE).x:
		size.x = get_meta(DFLT_SIZE).x
	lbl.free()
	rt.free()
	# ===================================== Calculate the width of the node ====
	# Define default position (before calculating overflow)
	rect_size = size
	rect_position = props.position - rect_size / 2.0
	rect_position.y -= rect_size.y / 2.0
	
	# Calculate overflow and reposition
	if rect_position.x < 0.0:
		rect_position.x = limit_margin
	elif rect_position.x + rect_size.x > _x_limit:
		rect_position.x = _x_limit - limit_margin - rect_size.x
	if rect_position.y < 0.0:
		rect_position.y = limit_margin
	elif rect_position.y + rect_size.y > _y_limit:
		rect_position.y = _y_limit - limit_margin - rect_size.y
	
	# Assign text and align mode (based on overflow)
	push_color(props.color)
	
	var center := floor(rect_position.x + (size.x / 2))
	if center == props.position.x:
		append_bbcode('[center]%s[/center]' % msg)
	elif center < props.position.x:
		append_bbcode('[right]%s[/right]' % msg)
	else:
		append_bbcode(msg)

	if _secs_per_character > 0.0:
		# Que el texto aparezca animado
		_tween.interpolate_property(
			self, 'percent_visible',
			0, 1,
			_secs_per_character * get_total_character_count(),
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
		)
		_tween.start()
	else:
		_wait_input()

	modulate.a = 1.0


func stop() ->void:
	if modulate.a == 0.0:
		return

	if _is_waiting_input:
		_notify_completion()
	else:
		# Saltarse las animaciones
		_tween.remove_all()
		percent_visible = 1.0
		
		_wait_input()


func hide() -> void:
	if modulate.a == 0.0: return
	
	_auto_continue = false
	modulate.a = 0.5
	_is_waiting_input = false
	
	_tween.remove_all()
	clear()
	
	_continue_icon.hide()
	_continue_icon.modulate.a = 1.0
	_continue_icon_tween.remove_all()
	
	rect_size = get_meta(DFLT_SIZE)


func change_speed() -> void:
	_secs_per_character = E.current_text_speed


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _show_dialogue(chr: PopochiuCharacter, msg := '') -> void:
	play_text({
		text = msg,
		color = chr.text_color,
		position = U.get_screen_coords_for(chr.dialog_pos).floor() / (
			E.scale if E.settings.scale_gui else Vector2.ONE
		),
	})


func _wait_input() -> void:
	_is_waiting_input = true
	
	if E.auto_continue_after >= 0.0:
		_auto_continue = true
		yield(get_tree().create_timer(E.auto_continue_after + 0.2), 'timeout')
		
		if _auto_continue:
			_continue(true)
	else:
		_show_icon()


func _notify_completion() -> void:
	self.hide()
	emit_signal('animation_finished')


func _show_icon() -> void:
	if not E.settings.auto_continue_text:
		# For manual continuation: make the continue icon jump
		_continue_icon.value = 100.0
		_continue_icon_tween.interpolate_property(
			_continue_icon, 'rect_position:y',
			rect_size.y,
			rect_size.y + 3.0,
			0.8,
			Tween.TRANS_BOUNCE, Tween.EASE_OUT
		)
		_continue_icon_tween.repeat = true
	else:
		# For automatic continuation: Make the icon appear like a progress bar
		# the time players wil have to read befor auto-continuing
		_continue_icon.value = 0.0
		_continue_icon_tween.interpolate_property(
			_continue_icon, 'value',
			null, 100.0, 3.0,
			Tween.TRANS_LINEAR, Tween.EASE_OUT
		)
		_continue_icon_tween.repeat = false

	yield(get_tree().create_timer(0.2), 'timeout')

	_continue_icon_tween.start()
	_continue_icon.show()


func _continue(forced_continue := false) -> void:
	if E.settings.auto_continue_text or forced_continue:
		G.emit_signal('continue_clicked')
