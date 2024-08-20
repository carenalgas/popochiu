@tool
class_name PopochiuInventoryGrid
extends HBoxContainer

const EMPTY_SLOT := "[Empty Slot]00"

@export var slot_scene: PackedScene = null : set = set_slot_scene
@export var columns := 4 : set = set_columns
@export var visible_rows := 2 : set = set_visible_rows
@export var number_of_slots := 16 : set = set_number_of_slots
@export var h_separation := 0 : set = set_h_separation
@export var v_separation := 0 : set = set_v_separation
@export var show_arrows := true : set = set_show_arrows
@export var scroll_with_mouse_wheel := true

var rows := 0
var max_scroll := 0.0

var slot_size: float = 0.0

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var box: GridContainer = %Box
@onready var scroll_buttons: VBoxContainer = $ScrollButtons
@onready var up: TextureButton = %Up
@onready var down: TextureButton = %Down
@onready var gap_size: int = box.get_theme_constant("v_separation")


#region Godot ######################################################################################
func _ready():
	if Engine.is_editor_hint():
		_update_box()
		return
	
	scroll_container.mouse_filter = (
		Control.MOUSE_FILTER_PASS if scroll_with_mouse_wheel else Control.MOUSE_FILTER_IGNORE
	)
	
	_update_box()
	_calculate_rows_and_scroll()
#	_check_starting_items()
	
	# Connect to child signals
	up.pressed.connect(_on_up_pressed)
	down.pressed.connect(_on_down_pressed)
	scroll_container.get_v_scroll_bar().value_changed.connect(_on_scroll)
	
	# Connect to singletons signals
	I.item_added.connect(_add_item)
	I.item_removed.connect(_remove_item)
	I.item_replaced.connect(_replace_item)
	
	_check_scroll_buttons()


#endregion

#region SetGet #####################################################################################
func set_visible_rows(value: int) -> void:
	visible_rows = value
	_update_box()


func set_columns(value: int) -> void:
	columns = value
	_update_box()


func set_slot_scene(value: PackedScene) -> void:
	slot_scene = value
	_update_box()


func set_number_of_slots(value: int) -> void:
	number_of_slots = value
	_update_box()


func set_h_separation(value: int) -> void:
	h_separation = value
	_update_box()


func set_v_separation(value: int) -> void:
	v_separation = value
	_update_box()


func set_show_arrows(value: bool) -> void:
	show_arrows = value
	
	if is_instance_valid(scroll_buttons):
		scroll_buttons.visible = value


#endregion

#region Private ####################################################################################
func _update_box() -> void:
	if not is_instance_valid(box): return
	
	box.columns = columns
	box.add_theme_constant_override("h_separation", h_separation)
	box.add_theme_constant_override("v_separation", v_separation)
	
	# Fix: remove the child immediately (instead of calling queue_free()), and do not await for
	# a process frame cause it can cause an issue when adding items marked as "Start with it".
	for child in box.get_children():
		child.free()
	
	for idx in number_of_slots:
		var slot := slot_scene.instantiate()
		box.add_child(slot)
		
		slot.name = EMPTY_SLOT
		slot_size = slot.size.y
	
	scroll_container.custom_minimum_size = Vector2(
		(columns * (slot_size + h_separation)) - h_separation,
		(visible_rows * (slot_size + v_separation)) - v_separation
	)


## Calculate the number of rows in the box and the max scroll
func _calculate_rows_and_scroll() -> void:
	var visible_slots := 0
	for slot in box.get_children():
		if slot.visible:
			visible_slots += 1
	@warning_ignore("integer_division")
	rows = visible_slots / box.columns
	max_scroll = ((slot_size + gap_size) * int(rows / 2))


## Check if there are inventory items in the scene tree and add them to the
## Inventory interface class (I).
func _check_starting_items() -> void:
	for slot in box.get_children():
		if (slot.get_child_count() > 0
		and slot.get_child(0) is PopochiuInventoryItem
		):
			I.items.append(slot.get_child(0).script_name)
			slot.name = slot.get_child(0).script_name
		else:
			slot.name = EMPTY_SLOT


func _on_up_pressed() -> void:
	scroll_container.scroll_vertical -= (slot_size + gap_size) + 1
	_check_scroll_buttons()


func _on_down_pressed() -> void:
	scroll_container.scroll_vertical += (slot_size + gap_size) + 1
	_check_scroll_buttons()


func _add_item(item: PopochiuInventoryItem, _animate := true) -> void:
	var slot := box.get_child(I.items.size() - 1)
	slot.name = "[%s]" % item.script_name
	slot.add_child(item)
	
	item.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	
	if slot.has_method("get_content_height"):
		item.custom_minimum_size.y = slot.get_content_height()
	else:
		item.custom_minimum_size.y = slot.size.y
	
	box.set_meta(item.script_name, slot)
	
	item.selected.connect(_change_cursor)
	_check_scroll_buttons()
	
	# Common call to all inventories. Should be in the class from where inventory panels will
	# inherit from
	await get_tree().process_frame
	
	I.item_add_done.emit(item)


func _remove_item(item: PopochiuInventoryItem, _animate := true) -> void:
	item.selected.disconnect(_change_cursor)
	
	box.get_meta(item.script_name).remove_child(item)
	box.get_meta(item.script_name).name = EMPTY_SLOT
	
	_check_scroll_buttons()
	
	await get_tree().process_frame
	
	I.item_remove_done.emit(item)


func _replace_item(
	item: PopochiuInventoryItem, new_item: PopochiuInventoryItem
) -> void:
	item.replace_by(new_item)
	box.remove_meta(item.script_name)
	box.set_meta(new_item.script_name, new_item.get_parent())
	
	_check_scroll_buttons()
	
	await get_tree().process_frame
	
	I.item_replace_done.emit()


func _change_cursor(item: PopochiuInventoryItem) -> void:
	I.set_active_item(item)


## Checks if the UP and DOWN buttons should be enabled
func _check_scroll_buttons() -> void:
	up.disabled = scroll_container.scroll_vertical == 0
	down.disabled = (
		scroll_container.scroll_vertical >= max_scroll
		or not (I.items.size() > box.columns * visible_rows)
	)


func _on_scroll(_value: float) -> void:
	_check_scroll_buttons()


#endregion
