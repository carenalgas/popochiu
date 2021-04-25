extends Node

signal show_info_requested(info)
signal show_box_requested(message)
signal inline_dialog_requested(options)
signal continue_clicked
signal freed

# TODO: Estas señales tendrán que ir en el Autoload destinado al sistema de
# diálogo.
signal option_selected(opt)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
# Muestra un texto en el centro de la pantalla. Puede servir para dar
# instrucciones o indicaciones de un narrador. Algo que definitivamente
# no hace parte del mundo del juego (o sea, que no ha sido dicho por un personaje).
func display(msg: String, no_yield := false) -> void:
	if not no_yield:
		yield()
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


# Retorna la opción seleccionada en el diálogo creado en tiempo de ejecución.
# NOTA: El flujo del juego se pausa hasta que el jugador seleccione una opción.
func show_inline_dialog(opts: Array) -> String:
	emit_signal('inline_dialog_requested', opts)
	return yield(self, 'option_selected')
