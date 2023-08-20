extends PopochiuGraphicInterface


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	super()
	
	Cursor.replace_frames($Cursor)
	Cursor.show_cursor()
	
	$Cursor.hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _on_system_text_shown(msg: String) -> void:
	G.show_hover_text()
	Cursor.show_cursor("wait", true)


func _on_system_text_hidden() -> void:
	if I.active:
		Cursor.hide_main_cursor()
		Cursor.show_secondary_cursor()
	else:
		Cursor.show_cursor()


func _on_mouse_entered_clickable(clickable: PopochiuClickable) -> void:
	if G.is_blocked: return
	
	if not I.active:
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


func _on_mouse_exited_clickable(clickable: PopochiuClickable) -> void:
	if G.is_blocked: return
	
	G.show_hover_text()
	
	if I.active: return
	
	Cursor.show_cursor()


func _on_mouse_entered_inventory_item(inventory_item: PopochiuInventoryItem) -> void:
	if G.is_blocked: return
	
	if not I.active:
		if inventory_item.get("cursor"):
			Cursor.show_cursor(Cursor.get_type_name(inventory_item.cursor))
		else:
			Cursor.show_cursor("active")
	
	if not I.active:
		G.show_hover_text(inventory_item.description)
	else:
		G.show_hover_text(
			'Use %s with %s' % [I.active.description, inventory_item.description]
		)


func _on_mouse_exited_inventory_item(inventory_item: PopochiuInventoryItem) -> void:
	if G.is_blocked: return
	
	G.show_hover_text()
	
	if I.active or $SettingsBar.is_open(): return
	
	Cursor.show_cursor()


func _on_dialog_line_started() -> void:
	Cursor.show_cursor("wait")


func _on_dialog_line_finished() -> void:
	Cursor.show_cursor("use" if D.current_dialog else "normal")


func _on_dialog_started(dialog: PopochiuDialog) -> void:
	Cursor.show_cursor("use")
	G.show_hover_text()


func _on_dialog_finished(dialog: PopochiuDialog) -> void:
	Cursor.show_cursor()


func _on_inventory_item_selected(item: PopochiuInventoryItem) -> void:
	if is_instance_valid(item):
		Cursor.hide_main_cursor()
	else:
		Cursor.show_cursor()
