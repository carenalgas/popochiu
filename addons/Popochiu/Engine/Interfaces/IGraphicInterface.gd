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
signal save_requested(date) # The date in YYYY/MM/DD HH:MM:SS format
signal load_requested
signal continue_requested

var is_blocked := false


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func display(msg: String) -> Callable:
	return func (): await display_no_run(msg)


# Shows a text in the center of the screen. Can be used as the narrator or to
# give instructions to players. The visual style of the node that shows this text
# can be modified in DisplayBox.tscn.
func display_no_run(msg: String) -> void:
	if not E.in_run():
		# Show the click handler that blocks interactions
		block()
	
	if E.cutscene_skipped:
		await get_tree().process_frame
		return
	
	show_box_requested.emit(E.get_text(msg))
	
	await self.continue_clicked


# Shows a text at the bottom of the screen. It is used to show players the
# name of nodes where the cursor is positioned (e.g. a Prop, a character). Could
# be used to show what will happen when players use left and right click.
func show_info(msg := '') -> void:
	show_info_requested.emit(msg)


# Makes the Graphic Interface to block.
func block() -> void:
	Cursor.set_cursor(Cursor.Type.WAIT)
	blocked.emit()
	is_blocked = true
	Cursor.block()


# Notifies that graphic interface elements can be unlocked (e.g. when a cutscene
# has ended).
func done() -> void:
	is_blocked = false
	Cursor.unlock()
	Cursor.set_cursor()
	freed.emit()


# Notifies that the graphic interface should hide.
func hide_interface() -> void:
	interface_hidden.emit()


# Notifies that the graphic interface should show.
func show_interface() -> void:
	interface_shown.emit()


# Notifies that the history of events should appear.
func show_history() -> void:
	history_opened.emit()


func show_save(date: String) -> void:
	save_requested.emit(date)


func show_load() -> void:
	load_requested.emit()
