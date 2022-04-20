extends RichTextLabel
# Permite mostrar textos caracter por caracter en un RichTextLabel para aprove-
# char sus capacidades de animación y edición de fragmentos de texto.
# Se usa un Label invisible para saber qué ancho debe tener este nodo

signal animation_finished

export var wrap_width := 200.0
export var min_wrap_width := 120

var _secs_per_character := 1.0
var _is_waiting_input := false
var _max_width := rect_size.x
var _dflt_height := rect_size.y
var _label_dflt_size := Vector2.ZERO

onready var _tween: Tween = $Tween
onready var _wrap_width_limit := (wrap_width / 2) * 0.3
onready var _continue_icon: TextureProgress = find_node('ContinueIcon')
onready var _continue_icon_tween: Tween = _continue_icon.get_node('Tween')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	# Establecer la configuración inicial
	clear()
	$Label.text = ''
	modulate.a = 0.0
	_secs_per_character = E.text_speeds[E.text_speed_idx]
	_continue_icon.hide()
	
	yield(get_tree(), 'idle_frame')
	_label_dflt_size = $Label.rect_size
	rect_size = Vector2(0.0, _dflt_height)
	
	# Conectarse a señales de los hijos
	_tween.connect('tween_all_completed', self, '_wait_input')
	_continue_icon_tween.connect('tween_all_completed', self, '_continue')
	
	# Conectarse a eventos del universo Chimpoko
	E.connect('text_speed_changed', self, 'change_speed')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func play_text(props: Dictionary) -> void:
	# Establecer el estado por defecto
	_is_waiting_input = false
	var msg: String = E.get_text(props.text)

	# Hacer los cálculos con el Label
	$Label.text = ''
	clear()

	yield(get_tree(), 'idle_frame')

	$Label.autowrap = false
	$Label.rect_size = _label_dflt_size
	rect_size = Vector2.ZERO

	$Label.text = msg

	yield(get_tree(), 'idle_frame')
	
	rect_size = Vector2($Label.rect_size.x, _dflt_height)
	
	# 1. Calcular el ancho que tendrá el nodo y su posición.
	if $Label.rect_size.x > wrap_width:
		$Label.rect_size.x = wrap_width
		$Label.autowrap = true
		rect_size.x = wrap_width
	
	rect_position = props.position
	rect_position.x -= $Label.rect_size.x / 2

	if (rect_position.x < -_wrap_width_limit or
	rect_position.x + $Label.rect_size.x > E.game_width + _wrap_width_limit):
		# Si el texto se sale de la pantalla, se ajusta el tamaño del nodo a su
		# valor mínimo.
		$Label.rect_size.x = min_wrap_width
		rect_size.x = min_wrap_width

	rect_position.x = props.position.x - (rect_size.x / 2)
	if rect_position.x < 0:
		rect_position.x = 4.0
	elif rect_position.x + rect_size.x > E.game_width:
		rect_position.x = E.game_width - rect_size.x - 4.0

	# 2. Asignar los textos al nodo y su alineación.
	push_color(props.color)
	
	var center := floor(rect_position.x + (rect_size.x / 2))
	if center == props.position.x:
#		clear()
#		push_color(props.color)
		append_bbcode('[center]%s[/center]' % msg)
#		yield(get_tree(), 'idle_frame')
	elif center < props.position.x:
#		clear()
#		push_color(props.color)
		append_bbcode('[right]%s[/right]' % msg)
#		yield(get_tree(), 'idle_frame')
	else:
		append_bbcode(msg)

	# 3. Ajustar la posición en Y con base a la altura del nodo.
	yield(get_tree(), 'idle_frame')
	rect_position.y -= rect_size.y
	
	# 4. Poner el icono de continuación
	_continue_icon.rect_position = rect_size

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
		_show_icon()

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

	modulate.a = 0.0
	_tween.remove_all()
	_is_waiting_input = false
	clear()
	_continue_icon.hide()
	_continue_icon.modulate.a = 1.0
	_continue_icon_tween.remove_all()
	
	yield(get_tree(), 'idle_frame')

	rect_size = Vector2.ZERO


func change_speed(idx: int) -> void:
	_secs_per_character = E.text_speeds[idx]


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _wait_input() -> void:
	_is_waiting_input = true
	
	_show_icon()


func _notify_completion() -> void:
	self.hide()
	emit_signal('animation_finished')


func _show_icon() -> void:
	if not E.text_continue_auto:
		# Hacer que el icono empiece a saltar.
		_continue_icon.value = 100.0
		_continue_icon_tween.interpolate_property(
			_continue_icon, 'rect_position:y',
			0.0, 3.0, 0.8,
			Tween.TRANS_BOUNCE, Tween.EASE_OUT
		)
		_continue_icon_tween.repeat = true
	else:
		# Por defecto, se vaya llenando el icono el tiempo que quede para que se
		# pase automáticamente a la siguiente línea.
		_continue_icon.value = 0.0
		_continue_icon_tween.interpolate_property(
			_continue_icon, 'value',
			0.0, 100.0, 3.0,
			Tween.TRANS_LINEAR, Tween.EASE_OUT
		)
		_continue_icon_tween.repeat = false
	
	yield(get_tree().create_timer(0.2), 'timeout')
	_continue_icon_tween.start()
	_continue_icon.show()


func _continue() -> void:
	if E.text_continue_auto:
		G.emit_signal('continue_clicked')
