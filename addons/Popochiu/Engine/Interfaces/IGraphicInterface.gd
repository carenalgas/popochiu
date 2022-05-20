extends Node
# (G) Data and functions to work with the graphic interface.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
# warning-ignore-all:unused_signal

signal show_info_requested(info)
signal show_box_requested(message)
signal continue_clicked
signal freed
signal blocked
signal interface_hidden
signal interface_shown
signal history_opened

var is_blocked := false


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Shows a text in the center of the screen. Can be used as the narrator or to
# give instructions to players. The visual style of the node that shows this text
# can be modified in DisplayBox.tscn.
func display(msg: String, is_in_queue := true) -> void:
	if is_in_queue: yield()

	if E.cutscene_skipped:
		yield(get_tree(), 'idle_frame')
		return
	
	emit_signal('show_box_requested', E.get_text(msg))
	yield(self, 'continue_clicked')


# Shows a text at the bottom of the screen. It is used to show players the
# name of nodes where the cursor is positioned (e.g. a Prop, a character). Could
# be used to show what will happen when players use left and right click.
func show_info(msg := '') -> void:
	emit_signal('show_info_requested', msg)


# Makes the Graphic Interface to block.
func block() -> void:
	Cursor.set_cursor(Cursor.Type.WAIT)
	emit_signal('blocked')
	is_blocked = true


# Notifies that graphic interface elements can be unlocked (e.g. when a cutscene
# has ended).
func done() -> void:
	Cursor.set_cursor()
	emit_signal('freed')
	is_blocked = false


# Notifies that the graphic interface should hide.
func hide_interface() -> void:
	emit_signal('interface_hidden')


# Notifies that the graphic interface should show.
func show_interface() -> void:
	emit_signal('interface_shown')


# Notifies that the history of events should appear.
func show_history() -> void:
	emit_signal('history_opened')
