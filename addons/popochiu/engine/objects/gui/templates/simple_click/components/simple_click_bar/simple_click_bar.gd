extends Control

@export var always_visible := false
@export var hide_when_gui_is_blocked := false
## Defines the height in pixels of the zone where moving the mouse in the top of the screen will
## make the bar to show. Note: This value will be affected by the Experimental Scale GUI checkbox
## in Project Settings > Popochiu > GUI.
@export var input_zone_height := 4

var is_disabled := false
var tween: Tween = null

var _is_hidden := true
var _is_mouse_hover := false

@onready var panel_container: PanelContainer = %PanelContainer
@onready var box: HBoxContainer = %Box
@onready var settings_btn: TextureButton = %SettingsBtn
@onready var hidden_y := panel_container.position.y - panel_container.size.y


#region Godot ######################################################################################
func _ready():
	if not always_visible:
		panel_container.position.y = hidden_y
	
	# Connect to children signals
	settings_btn.pressed.connect(_on_settings_pressed)
	settings_btn.mouse_entered.connect(_on_settings_mouse_entered)
	settings_btn.mouse_exited.connect(_on_settings_mouse_exited)
	
	# Connect to singletons signals
	PopochiuUtils.i.item_added.connect(_add_item)
	PopochiuUtils.i.item_removed.connect(_remove_item)
	PopochiuUtils.i.item_replaced.connect(_replace_item)
	PopochiuUtils.i.inventory_show_requested.connect(_show_and_hide)
	PopochiuUtils.i.inventory_hide_requested.connect(_close)
	PopochiuUtils.g.blocked.connect(_on_gui_blocked)
	PopochiuUtils.g.unblocked.connect(_on_gui_unblocked)
	
	# Check if there are already items in the inventory (set manually in the scene)
	for ii in box.get_children():
		ii.in_inventory = ii is PopochiuInventoryItem
			#ii.selected.connect(_change_cursor)
	
	set_process_input(not always_visible)


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion: return
	if settings_btn.is_hovered(): return
	
	var rect := panel_container.get_rect()
	rect.size += Vector2(0.0, input_zone_height)
	if PopochiuUtils.e.settings.scale_gui:
		rect = Rect2(
			panel_container.get_rect().position * PopochiuUtils.e.scale,
			panel_container.get_rect().size * PopochiuUtils.e.scale
		)
	
	if rect.has_point(get_global_mouse_position()):
		_is_mouse_hover = true
		
		if PopochiuUtils.i.active:
			PopochiuUtils.cursor.hide_main_cursor()
			PopochiuUtils.cursor.show_secondary_cursor()
		else:
			PopochiuUtils.cursor.show_cursor("gui")
	elif _is_mouse_hover:
		_is_mouse_hover = false
		
		if PopochiuUtils.d.current_dialog:
			PopochiuUtils.cursor.show_cursor("gui")
		elif PopochiuUtils.g.gui.is_showing_dialog_line:
			PopochiuUtils.cursor.show_cursor("wait")
		else:
			PopochiuUtils.cursor.show_cursor("normal")
		
		if PopochiuUtils.i.active:
			PopochiuUtils.cursor.hide_main_cursor()
			PopochiuUtils.cursor.show_secondary_cursor()
	
	if _is_hidden and rect.has_point(get_global_mouse_position()):
		_open()
	elif not _is_hidden and not rect.has_point(get_global_mouse_position()):
		_close()


#endregion

#region Private ####################################################################################
func _on_settings_pressed() -> void:
	PopochiuUtils.g.popup_requested.emit("SimpleClickSettings")


func _on_settings_mouse_entered() -> void:
	if PopochiuUtils.i.active:
		PopochiuUtils.cursor.show_main_cursor()
		PopochiuUtils.cursor.hide_secondary_cursor()
	
	PopochiuUtils.cursor.show_cursor("gui")


func _on_settings_mouse_exited() -> void:
	if PopochiuUtils.g.is_blocked: return
	
	if PopochiuUtils.d.current_dialog:
		PopochiuUtils.cursor.show_cursor("gui")
	elif PopochiuUtils.g.gui.is_showing_dialog_line:
		PopochiuUtils.cursor.show_cursor("wait")
	else:
		PopochiuUtils.cursor.show_cursor("normal")
	
	if PopochiuUtils.i.active:
		PopochiuUtils.cursor.hide_main_cursor()
		PopochiuUtils.cursor.show_secondary_cursor()


func _open() -> void:
	if always_visible: return
	if not is_disabled and panel_container.position.y != hidden_y: return
	
	if is_instance_valid(tween) and tween.is_running():
		tween.kill()
	
	tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		panel_container, "position:y", 0.0, 0.5
	).from(hidden_y if not is_disabled else panel_container.position.y)
	
	_is_hidden = false


func _close() -> void:
	if always_visible: return
	await get_tree().process_frame
	
	if is_instance_valid(tween) and tween.is_running():
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(
		panel_container, "position:y",
		hidden_y if not is_disabled else hidden_y - 3.5,
		0.2
	).from(0.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	_is_hidden = true


func _on_tween_finished() -> void:
	_is_hidden = panel_container.position.y == hidden_y


func _add_item(item: PopochiuInventoryItem, animate := true) -> void:
	box.add_child(item)
	
	item.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	item.size_flags_vertical = Control.SIZE_FILL
	item.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	
	item.selected.connect(_change_cursor)
	
	if not always_visible and animate:
		# Show the inventory for a while and hide after a couple of seconds so players can see the
		# item being added to the inventory
		set_process_input(false)
		
		_open()
		await get_tree().create_timer(2.0).timeout
		
		# The mouse not being on the inventory can close the inventory prior to the 2 seconds
		# expiring. This check fixes this. Bug 350.
		if not _is_hidden:
			_close()
			await get_tree().create_timer(0.5).timeout

		set_process_input(true)
	else:
		await get_tree().process_frame
	
	PopochiuUtils.i.item_add_done.emit(item)


func _remove_item(item: PopochiuInventoryItem, animate := true) -> void:
	item.selected.disconnect(_change_cursor)
	box.remove_child(item)
	
	if not always_visible:
		PopochiuUtils.cursor.show_cursor()
		PopochiuUtils.g.show_hover_text()
		
		if animate:
			_close()
			await get_tree().create_timer(1.0).timeout
	
	await get_tree().process_frame
	
	PopochiuUtils.i.item_remove_done.emit(item)


func _change_cursor(item: PopochiuInventoryItem) -> void:
	PopochiuUtils.i.set_active_item(item)


func _replace_item(item: PopochiuInventoryItem, new_item: PopochiuInventoryItem) -> void:
	item.replace_by(new_item)
	await get_tree().process_frame
	
	PopochiuUtils.i.item_replace_done.emit()


func _show_and_hide(time := 1.0) -> void:
	set_process_input(false)
	_open()
	await tween.finished
	await PopochiuUtils.e.wait(time)
	
	_close()
	await tween.finished
	
	set_process_input(true)
	PopochiuUtils.i.inventory_shown.emit()


func _on_gui_blocked() -> void:
	set_process_input(false)
	
	if hide_when_gui_is_blocked:
		hide()


func _on_gui_unblocked() -> void:
	set_process_input(true)
	
	if hide_when_gui_is_blocked:
		show()


#endregion
