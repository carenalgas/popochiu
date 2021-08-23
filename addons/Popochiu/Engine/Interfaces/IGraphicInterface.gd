extends Node
# (G) Para hacer cosas con la interfaz gráfica
# TODO: Que todo esto vaya al script que se carga en la escena de la interfaz
# gráfica, que en últimas irá también al Autoload.

# warning-ignore-all:unused_signal
signal show_info_requested(info)
signal show_box_requested(message)
signal continue_clicked
signal freed
signal blocked
signal interface_hidden
signal inventory_show_requested(time)
signal inventory_shown
signal history_opened

var blocked := false
var waiting_click := false


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
# Muestra un texto en el centro de la pantalla. Puede servir para dar
# instrucciones o indicaciones de un narrador. Algo que definitivamente
# no hace parte del mundo del juego (o sea, que no ha sido dicho por un personaje).
func display(msg: String, is_in_queue := true) -> void:
	if is_in_queue: yield()

	if E.cutscene_skipped:
		yield(get_tree(), 'idle_frame')
		return
	
	emit_signal('show_box_requested', E.get_text(msg))
	yield(self, 'continue_clicked')


# Notifica que ya se pueden desbloquear lo elementos de la Interfaz Gráfica del
# Jugador porque una secuencia de eventos (o cinemática (cutscene)) ha terminado.
func done() -> void:
	Cursor.set_cursor()
	emit_signal('freed')


# Muestra un texto en la parte inferior de la pantalla. Se usa para mostrar al
# jugador el nombre del objeto sobre el cuál está el cursor y, eventualmente,
# podría mostrarse lo que ocurrirá cuando haga clic izquierdo o dereche (p.e. si
# hay un objeto del inventario seleccionado, podría en lugar de mostrarse el
# nombre del objeto, mostrar Usar ____ en ____).
func show_info(msg := '') -> void:
	emit_signal('show_info_requested', msg)


func block() -> void:
	Cursor.set_cursor(Cursor.Type.WAIT)
	emit_signal('blocked')


func hide_interface() -> void:
	emit_signal('interface_hidden')


func show_inventory(time := 1.0, is_in_queue := true) -> void:
	if is_in_queue: yield()
	
	if E.cutscene_skipped:
		yield(get_tree(), 'idle_frame')
		return
	
	emit_signal('inventory_show_requested', time)
	yield(self, 'inventory_shown')


func show_history() -> void:
	emit_signal('history_opened')
