extends Node

signal show_info_requested(info)
signal show_box_requested(message)
signal continue_clicked
signal freed
signal blocked


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
# Muestra un texto en el centro de la pantalla. Puede servir para dar
# instrucciones o indicaciones de un narrador. Algo que definitivamente
# no hace parte del mundo del juego (o sea, que no ha sido dicho por un personaje).
func display(msg: String, yield_on_start := true) -> void:
	if yield_on_start: yield()
	emit_signal('show_box_requested', msg)
	yield(self, 'continue_clicked')


# Notifica que ya se pueden desbloquear lo elementos de la Interfaz Gráfica del
# Jugador porque una secuencia de eventos (o cinemática (cutscene)) ha terminado.
func done() -> void:
	emit_signal('freed')


# Muestra un texto en la parte inferior de la pantalla. Se usa para mostrar al
# jugador el nombre del objeto sobre el cuál está el cursor y, eventualmente,
# podría mostrarse lo que ocurrirá cuando haga clic izquierdo o dereche (p.e. si
# hay un objeto del inventario seleccionado, podría en lugar de mostrarse el
# nombre del objeto, mostrar Usar ____ en ____).
func show_info(msg := '') -> void:
	emit_signal('show_info_requested', msg)


func block() -> void:
	emit_signal('blocked')
