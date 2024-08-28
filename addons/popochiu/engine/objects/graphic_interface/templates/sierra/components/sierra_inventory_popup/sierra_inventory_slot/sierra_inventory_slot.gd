extends PanelContainer

@export var hover_color := Color("ffffff")
@export var selected_color := Color("edf171")

var _is_selected := false

@onready var _style_box_flat: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
@onready var _dflt_border_color := _style_box_flat.border_color


#region Godot ######################################################################################
func _ready() -> void:
	add_theme_stylebox_override("panel", _style_box_flat)
	
	# Connect to own signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	child_entered_tree.connect(_on_item_assigned)
	child_exiting_tree.connect(_on_item_removed)


#endregion

#region Public #####################################################################################
func get_content_height() -> float:
	# Subtract the value of the sum of the top and bottom borders of the StyleBoxFlat of this slot
	return size.y - 2


#endregion

#region Private ####################################################################################
func _on_mouse_entered() -> void:
	_style_box_flat.border_color = hover_color


func _on_mouse_exited() -> void:
	_style_box_flat.border_color = _dflt_border_color if not _is_selected else selected_color


func _on_item_assigned(node: Node) -> void:
	if not node is PopochiuInventoryItem:
		return
	
	var inventory_item: PopochiuInventoryItem = node
	
	inventory_item.mouse_entered.connect(_on_mouse_entered)
	inventory_item.mouse_exited.connect(_on_mouse_exited)
	inventory_item.selected.connect(_on_item_selected)
	inventory_item.unselected.connect(_on_item_unselected)


func _on_item_removed(node: Node) -> void:
	if not node is PopochiuInventoryItem:
		return
	
	var inventory_item: PopochiuInventoryItem = node
	
	inventory_item.mouse_entered.disconnect(_on_mouse_entered)
	inventory_item.mouse_exited.disconnect(_on_mouse_exited)
	inventory_item.selected.disconnect(_on_item_selected)
	inventory_item.unselected.disconnect(_on_item_unselected)


func _on_item_selected(item: PopochiuInventoryItem) -> void:
	_style_box_flat.border_color = selected_color
	_is_selected = true


func _on_item_unselected() -> void:
	_is_selected = false
	_style_box_flat.border_color = _dflt_border_color


#endregion
