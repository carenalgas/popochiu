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

@onready var panel_container: PanelContainer = %PanelContainer
@onready var box: Container = %Box
@onready var hidden_y := panel_container.position.y - panel_container.size.y


#region Godot ######################################################################################
func _ready():
	if not always_visible:
		panel_container.position.y = hidden_y
	
	# Connect to singletons signals
	G.blocked.connect(_on_gui_blocked)
	G.unblocked.connect(_on_gui_unblocked)
	I.item_added.connect(_add_item)
	I.item_removed.connect(_remove_item)
	I.item_replaced.connect(_replace_item)
	I.inventory_show_requested.connect(_show_and_hide)
	I.inventory_hide_requested.connect(_close)
	
	# Check if there are already items in the inventory (set manually in the scene)
	for ii in box.get_children():
		if ii is PopochiuInventoryItem:
			ii.in_inventory = true
			ii.selected.connect(_change_cursor)
	
	set_process_input(not always_visible)


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion: return
	
	var rect := panel_container.get_rect()
	rect.size += Vector2(0.0, input_zone_height)
	if E.settings.scale_gui:
		rect = Rect2(
			panel_container.get_rect().position * E.scale,
			panel_container.get_rect().size * E.scale
		)
	
	if _is_hidden and rect.has_point(get_global_mouse_position()):
		_open()
	elif not _is_hidden and not rect.has_point(get_global_mouse_position()):
		_close()


#endregion

#region Private ####################################################################################
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


func _change_cursor(item: PopochiuInventoryItem) -> void:
	I.set_active_item(item)


func _on_gui_blocked() -> void:
	set_process_input(false)
	
	if hide_when_gui_is_blocked:
		hide()


func _on_gui_unblocked() -> void:
	set_process_input(true)
	
	if hide_when_gui_is_blocked:
		show()


func _add_item(item: PopochiuInventoryItem, animate := true) -> void:
	box.add_child(item)
	
	item.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	item.custom_minimum_size.y = box.size.y
	
	item.selected.connect(_change_cursor)
	
	if not always_visible and animate:
		# Show the inventory for a while and hide after a couple of seconds so players can see the
		# item being added to the inventory
		set_process_input(false)
		
		_open()
		await get_tree().create_timer(2.0).timeout
		
		_close()
		await get_tree().create_timer(0.5).timeout
		
		set_process_input(true)
	else:
		await get_tree().process_frame
	
	I.item_add_done.emit(item)


func _remove_item(item: PopochiuInventoryItem, animate := true) -> void:
	item.selected.disconnect(_change_cursor)
	box.remove_child(item)
	
	if not always_visible:
		Cursor.show_cursor()
		G.show_hover_text()
		
		if animate:
			_close()
			await get_tree().create_timer(1.0).timeout
	
	await get_tree().process_frame
	
	I.item_remove_done.emit(item)


func _replace_item(item: PopochiuInventoryItem, new_item: PopochiuInventoryItem) -> void:
	item.replace_by(new_item)
	await get_tree().process_frame
	
	I.item_replace_done.emit()


func _show_and_hide(time := 1.0) -> void:
	set_process_input(false)
	_open()
	await tween.finished
	await E.wait(time)
	
	_close()
	await tween.finished
	
	set_process_input(true)
	I.inventory_shown.emit()


#endregion
