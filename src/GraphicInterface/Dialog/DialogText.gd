class_name DialogText
extends RichTextLabel
# Permite mostrar textos caracter por caracter en un RichTextLabel para aprove-
# char sus capacidades de animación y edición de fragmentos de texto.

signal animation_finished

export var wrap_width := 200.0
export var min_wrap_width := 120

var _secs_per_character := 1.0
var _is_waiting_input := false
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
	rect_position = props.position
	rect_position.x -= rect_size.x / 2

	# Se usa un Label para saber el ancho y alto que tendrá el RichTextLabel
	$Label.text = text
	yield(get_tree(), 'idle_frame') # Para que se pueda calcular bien el ancho

	if $Label.rect_size.x > wrap_width:
		$Label.rect_size.x = wrap_width
		$Label.autowrap = true

	if rect_position.x < -_wrap_width_limit:
		rect_size.x = min_wrap_width
		rect_position.x = props.position.x - (rect_size.x / 2)
		yield(get_tree(), 'idle_frame') # Para que se pueda calcular bien el ancho
		
		if rect_position.x < 0:
			rect_position.x = 4.0
	elif rect_position.x + rect_size.x > E.game_width + _wrap_width_limit:
		rect_size.x = min_wrap_width
		rect_position.x = props.position.x - (rect_size.x / 2)
		yield(get_tree(), 'idle_frame') # Para que se pueda calcular bien el ancho

		if rect_position.x + rect_size.x > E.game_width:
			rect_position.x = E.game_width - rect_size.x - 4.0
	
	# Determinar cómo se debe alinear el texto
	var center := rect_position.x + (rect_size.x / 2)
	if center == props.position.x:
		clear()
		push_color(props.color)
		append_bbcode('[center]%s[/center]' % msg)
		yield(get_tree(), 'idle_frame') 
	elif center < props.position.x:
		clear()
		push_color(props.color)
		append_bbcode('[right]%s[/right]' % msg)
		yield(get_tree(), 'idle_frame') 

	# Ajustar la posición en Y del texto que dice el personaje	
	rect_position.y -= rect_size.y
	
	if _secs_per_character > 0.0:
		# Que el texto aparezca animado
		_tween.interpolate_property(
			self, 'percent_visible',
			0, 1,
			_secs_per_character * get_total_character_count(),
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
		_wait_input()


func hide() -> void:
	if modulate.a == 0.0: return

	modulate.a = 0.0
	_tween.stop_all()
	_is_waiting_input = false
	clear()
	yield(get_tree(), 'idle_frame')
	rect_size = Vector2(wrap_width, _dflt_height)


func change_speed(idx: int) -> void:
	_secs_per_character = E.text_speeds[idx]


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _wait_input() -> void:
	_is_waiting_input = true


func _notify_completion() -> void:
	self.hide()
	emit_signal('animation_finished')
