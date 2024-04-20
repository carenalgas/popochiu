class_name SimpleClickGUI
extends PopochiuGraphicInterface
## Defines the behavior of the 2-click Context-sensitive GUI.
##
## In this GUI, players interact with objects in the game based on the clicked mouse button. The
## inventory bar is in the top left corner of the screen, and the settings bar is in the top right
## corner of the screen.


#region Godot ######################################################################################
func _ready() -> void:
	super()
	
	Cursor.replace_frames($Cursor)
	Cursor.show_cursor()
	
	$Cursor.hide()


#endregion

#region Virtual ####################################################################################
## Called when a text is shown in the [SystemText] component. This erases the text in the
## [HoverText] component and shows the [code]"wait"[/code] cursor.
func _on_system_text_shown(msg: String) -> void:
	G.show_hover_text()
	Cursor.show_cursor("wait", true)


## Called when the [SystemText] component hides. If an [PopochiuInventoryItem] is active, the cursor
## takes its texture, otherwise it takes its default one.
func _on_system_text_hidden() -> void:
	if I.active:
		Cursor.hide_main_cursor()
		Cursor.show_secondary_cursor()
	else:
		Cursor.show_cursor()


## Called when the mouse enters (hovers) [param clickable]. It changes the texture of the cursor
## and displays a message with the [member PopochiuClickable.description] on the [HoverText]
## component.
func _on_mouse_entered_clickable(clickable: PopochiuClickable) -> void:
	if G.is_blocked: return
	
	if not (I.active or is_showing_dialog_line):
		if clickable.get("cursor"):
			Cursor.show_cursor(Cursor.get_type_name(clickable.cursor))
		else:
			Cursor.show_cursor("active")
	
	if not I.active:
		G.show_hover_text(clickable.description)
	else:
		G.show_hover_text(
			'Use %s with %s' % [I.active.description, clickable.description]
		)


## Called when the mouse exits [param clickable]. Clears the text in the [HoverText] component and
## shows the default cursor texture if there is no [PopochiuInventoryItem] active.
func _on_mouse_exited_clickable(clickable: PopochiuClickable) -> void:
	G.show_hover_text()
	
	if I.active or is_showing_dialog_line: return
	
	Cursor.show_cursor("gui" if D.current_dialog else "normal")


## Called when the mouse enters (hovers) [param inventory_item]. It changes the texture of the
## cursor and displays a message with the [member PopochiuInventoryItem.description] on the
## [HoverText] component.
func _on_mouse_entered_inventory_item(inventory_item: PopochiuInventoryItem) -> void:
	if G.is_blocked: return
	
	if not I.active:
		if inventory_item.get("cursor"):
			Cursor.show_cursor(Cursor.get_type_name(inventory_item.cursor))
		else:
			Cursor.show_cursor("active")
		
		G.show_hover_text(inventory_item.description)
	elif I.active != inventory_item:
		G.show_hover_text(
			'Use %s with %s' % [I.active.description, inventory_item.description]
		)
	else:
		G.show_hover_text(inventory_item.description)


## Called when the mouse exits [param inventory_item]. Clears the text in the [HoverText] component
## and shows the default cursor texture if there is no [PopochiuInventoryItem] active.
func _on_mouse_exited_inventory_item(inventory_item: PopochiuInventoryItem) -> void:
	if G.is_blocked: return
	
	G.show_hover_text()
	
	if I.active or $SettingsBar.is_open(): return
	
	Cursor.show_cursor()


## Called when a dialog line starts. It shows the [code]"wait"[/code] cursor.
func _on_dialog_line_started() -> void:
	is_showing_dialog_line = true
	Cursor.show_cursor("wait")


## Called when a dialog line finishes. It shows the [code]"normal"[/code] cursor if there is no
## [PopochiuDialog] active, otherwise shows the [code]"use"[/code] cursor.
func _on_dialog_line_finished() -> void:
	is_showing_dialog_line = false
	if D.current_dialog:
		Cursor.show_cursor("gui")
	elif E.hovered:
		Cursor.show_cursor(Cursor.get_type_name(E.hovered.cursor))
	else:
		Cursor.show_cursor("normal")


## Called when a [PopochiuDialog] starts. It shows the [code]"use"[/code] cursor and clears the
## [HoverText] component.
func _on_dialog_started(dialog: PopochiuDialog) -> void:
	Cursor.show_cursor("gui")
	G.show_hover_text()


## Called when the running [PopochiuDialog] shows its options on screen. It shows the
## [code]"gui"[/code] cursor.
func _on_dialog_options_shown() -> void:
	Cursor.unblock()
	Cursor.show_cursor("gui")


## Called when a [PopochiuDialog] finishes. It shows the default cursor.
func _on_dialog_finished(dialog: PopochiuDialog) -> void:
	Cursor.show_cursor()


## Called when the active [PopochiuInventoryItem] changes. If there is one, it hides the main cursor
## to show the one that shows the [member PopochiuInventoryItem.texture], otherwise it shows the
## default cursor.
func _on_inventory_item_selected(item: PopochiuInventoryItem) -> void:
	if is_instance_valid(item):
		Cursor.set_secondary_cursor_texture(item.texture)
		Cursor.hide_main_cursor()
	else:
		Cursor.remove_secondary_cursor_texture()
		Cursor.show_cursor()


#endregion
