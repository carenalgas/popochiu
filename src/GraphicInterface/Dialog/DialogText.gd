class_name DialogText
extends RichTextLabel
# Permite mostrar textos caracter por caracter en un RichTextLabel para aprove-
# char sus capacidades de animación y edición de fragmentos de texto.

signal animation_finished

export var wrap_width := 200
export var min_wrap_width := 120

var _secs_per_character := 1.0
var _is_waiting_input := false
var _target_size := Vector2.ONE
var _max_width := rect_size.x
var _dflt_height := rect_size.y

onready var _tween: Tween = $Tween
onready var _label_dflt_size: Vector2 = $Label.rect_size
onready var _wrap_width_limit := (wrap_width / 2) * 0.2


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	# Establecer la configuración inicial
	clear()
	$Label.text = ''
	modulate.a = 0.0
	_secs_per_character = E.text_speeds[E.text_speed_idx]
	
	# Conectarse a señales de los hijos
	_tween.connect('tween_all_completed', self, '_wait_input')
	
	# Conectarse a eventos del universo Chimpoko
	E.connect('text_speed_changed', self, 'change_speed')
	
	prints('_wrap_width_limit', _wrap_width_limit)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func play_text(props: Dictionary) -> void:
	# Establecer el estado por defecto
	_is_waiting_input = false
	var msg: String = E.get_text(props.text)

	clear()
	push_color(props.color)
	$Label.text = ''
	$Label.autowrap = false
	$Label.rect_size.x = 0.0
	yield(get_tree(), 'idle_frame') # Para que se pueda calcular bien el ancho
	
	append_bbcode(msg)
	rect_size = Vector2(wrap_width, _dflt_height)

	# Se usa un Label para saber el ancho y alto que tendrá el RichTextLabel
	$Label.text = text
	rect_position = props.position
	yield(get_tree(), 'idle_frame') # Para que se pueda calcular bien el ancho

	if $Label.rect_size.x > wrap_width:
		$Label.rect_size.x = wrap_width
		$Label.autowrap = true
	
	_target_size = Vector2($Label.rect_size.x, $Label.rect_size.y)
	
#	rect_size = _target_size
#	rect_position.y -= 12.0

	# Ajustar la posición en X del texto que dice el personaje
	rect_position.x -= rect_size.x / 2
	
	prints('X:', rect_position.x)

	if rect_position.x < -_wrap_width_limit:
#		_target_size.x = min_wrap_width
#		_target_size.y = _dflt_height + (($Label.get_line_count() - 1))
		rect_size.x = min_wrap_width
		yield(get_tree(), 'idle_frame') # Para que se pueda calcular bien el ancho

		rect_position.x = 4.0
#		rect_position.y -= 12.0
	elif rect_position.x + rect_size.x > E.game_width + _wrap_width_limit:
#		_target_size.x = min_wrap_width
#		_target_size.y = _dflt_height + (($Label.get_line_count() - 1))
		rect_size.x = min_wrap_width
		yield(get_tree(), 'idle_frame') # Para que se pueda calcular bien el ancho

		rect_position.x = E.game_width - rect_size.x - 4.0
#		rect_position.y -= 12.0

		clear()
		push_color(props.color)
		append_bbcode('[right]%s[/right]' % msg)
	else:
		clear()
		push_color(props.color)
		append_bbcode('[center]%s[/center]' % msg)
	
	# Ajustar la posición en Y del texto que dice el personaje	
#	rect_position.y -= _target_size.y
	rect_position.y -= rect_size.y
	prints('alto:', rect_size.y)

	if _secs_per_character > 0.0:
		# Que el texto aparezca animado
		_tween.interpolate_property(
			self, 'percent_visible',
			0, 1,
			_secs_per_character * $Label.get_total_character_count(),
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
		)
		_tween.start()

	modulate.a = 1.0


func stop() ->void:
	if modulate.a == 0.0:
		return

	if _is_waiting_input:
		_notify_completion()
	else:
		# Saltarse las animaciones
		_tween.stop_all()
		percent_visible = 1.0
#		rect_size = _target_size
		_wait_input()


func hide() -> void:
	modulate.a = 0.0
	_tween.stop_all()
	_is_waiting_input = false


func change_speed(idx: int) -> void:
	_secs_per_character = E.text_speeds[idx]


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _wait_input() -> void:
	_is_waiting_input = true


func _notify_completion() -> void:
	self.hide()
	emit_signal('animation_finished')
