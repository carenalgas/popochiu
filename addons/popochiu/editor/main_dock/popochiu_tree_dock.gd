@tool
class_name PopochiuTreeDock
extends VBoxContainer
# Base class for Popochiu dock tabs that display grouped items using a native [Tree] control.
#
# Handles the Tree setup, the filter LineEdit, the right-click context menu, and common helpers to
# create groups and items. Subclasses must provide a scene with a `%Filter` [LineEdit] and a `%Tree`
# [Tree] node, and implement the virtual methods to build their own content.
#
# Ref: #558

signal item_clicked(item: TreeItem)
signal button_clicked(item: TreeItem, id: int)
signal create_clicked(group_item: TreeItem)
signal menu_item_selected(item: TreeItem, id: int)

const COL_TEXT := 0
const COL_TAG := 1
const COL_BUTTONS := 2

const MENU_SEPARATOR := -1
const MENU_BUTTON_ID := 100

var _context_menu: PopupMenu
var _context_item: TreeItem

@onready var filter: LineEdit = %Filter
@onready var tree: Tree = %Tree


#region Godot ######################################################################################
func _ready() -> void:
	_setup_filter()
	_setup_tree()
	_setup_context_menu()


#endregion

#region Public #####################################################################################
## Creates a group item (a parent item in the Tree) with an optional "+" create button.
func create_group(
	title: String, icon: Texture2D, can_create := true, create_text := "", data: Dictionary = {}
) -> TreeItem:
	# Ensure the hidden root exists first so groups are always its children, never the root itself
	var root := tree.get_root()
	if not root:
		root = tree.create_item()
	var group := tree.create_item(root)
	group.set_text(COL_TEXT, title)
	group.set_icon(COL_TEXT, icon)
	
	var meta := data.duplicate()
	meta["title"] = title
	meta["can_create"] = can_create
	meta["create_text"] = create_text
	group.set_metadata(COL_TEXT, meta)
	
	if can_create:
		add_button(group, get_theme_icon("Add", "EditorIcons"), 0, create_text)
	
	return group


## Appends a new item to [param group] as its last child, preserving the order in which items are
## discovered (no alphabetical sorting).
func add_item(group: TreeItem, name: String, icon: Texture2D, data: Dictionary = {}) -> TreeItem:
	var item := tree.create_item(group)
	item.set_text(COL_TEXT, name)
	item.set_icon(COL_TEXT, icon)
	item.set_metadata(COL_TEXT, data)
	item.set_tooltip_text(COL_TEXT, data.get("path", ""))
	update_group_count(group)
	return item


## Adds an icon button to the item's buttons column.
func add_button(item: TreeItem, icon: Texture2D, id: int, tooltip := "") -> void:
	item.add_button(COL_BUTTONS, icon, id, false, tooltip)


## Adds the three-dots button that opens the context menu for the item.
func add_menu_button(item: TreeItem) -> void:
	add_button(item, get_theme_icon("GuiTabMenuHl", "EditorIcons"), MENU_BUTTON_ID, "Options")


## Shows or hides the status tag icon (e.g. main scene, PC, start-with-it) on the item.
func set_tag(item: TreeItem, icon: Texture2D, value: bool) -> void:
	if value:
		item.set_icon(COL_TAG, icon)
	else:
		item.set_icon(COL_TAG, null)


## Dims or restores the item text to indicate whether the object is part of Popochiu or not.
func set_dimmed(item: TreeItem, dimmed: bool) -> void:
	if dimmed:
		item.set_custom_color(COL_TEXT, Color(1, 1, 1, 0.5))
	else:
		item.clear_custom_color(COL_TEXT)


## Updates the group title with its child count, mirroring the old group behavior of showing the
## count only when there is more than one child.
func update_group_count(group: TreeItem) -> void:
	var title: String = group.get_metadata(COL_TEXT).title
	var count := group.get_child_count()
	group.set_text(COL_TEXT, "%s (%d)" % [title, count] if count > 1 else title)


## Enables or disables the group's create button.
func set_create_disabled(group: TreeItem, disabled: bool) -> void:
	var btn_idx := group.get_button_by_id(COL_BUTTONS, 0)
	if btn_idx >= 0:
		group.set_button_disabled(COL_BUTTONS, btn_idx, disabled)


## Clears the status tag icon on every child of [param group].
func clear_group_tags(group: TreeItem) -> void:
	for child in group.get_children():
		child.set_icon(COL_TAG, null)


## Returns the first child of [param group] whose text matches [param name], or null.
func get_item(group: TreeItem, name: String) -> TreeItem:
	for child in group.get_children():
		if child.get_text(COL_TEXT) == name:
			return child
	return null


## Removes [param item] from the Tree and updates its parent group count.
func remove_item(item: TreeItem) -> void:
	var group := item.get_parent()
	item.free()
	if group:
		update_group_count(group)


## Clears the whole Tree.
func clear() -> void:
	tree.clear()


#endregion

#region Private ####################################################################################
func _setup_filter() -> void:
	filter.placeholder_text = "Filter Popochiu objects"
	filter.clear_button_enabled = true
	filter.right_icon = get_theme_icon("Search", "EditorIcons")
	filter.text_changed.connect(_filter_items)


func _setup_tree() -> void:
	tree.columns = 3
	tree.hide_root = true
	tree.select_mode = Tree.SELECT_ROW
	tree.allow_rmb_select = true
	tree.set_column_expand(COL_TEXT, true)
	tree.set_column_expand(COL_TAG, false)
	tree.set_column_expand(COL_BUTTONS, false)
	tree.set_column_custom_minimum_width(COL_TAG, 16)
	
	tree.item_selected.connect(_on_item_selected)
	tree.button_clicked.connect(_on_button_clicked)
	tree.item_mouse_selected.connect(_on_item_mouse_selected)


func _setup_context_menu() -> void:
	_context_menu = PopupMenu.new()
	_context_menu.id_pressed.connect(_on_context_menu_id_pressed)
	add_child(_context_menu)


## Hides items whose name does not match the filter text, and hides groups with no visible items.
func _filter_items(new_text: String) -> void:
	var root := tree.get_root()
	if not root: return
	
	for group in root.get_children():
		group.set_visible(true)
		
		var title_in_filter := false
		var group_title: String = group.get_metadata(COL_TEXT).title
		if group_title.findn(new_text) > -1:
			title_in_filter = true
		
		var hidden_rows := 0
		var rows := group.get_children()
		
		for row in rows:
			row.set_visible(true)
			if new_text.is_empty(): continue
			if row.get_text(COL_TEXT).findn(new_text) < 0 and not title_in_filter:
				hidden_rows += 1
				row.set_visible(false)
		
		if hidden_rows == rows.size() and not new_text.is_empty():
			group.set_visible(false)


func _on_item_selected() -> void:
	var item := tree.get_selected()
	# Ignore group items (direct children of the hidden root)
	if item and item.get_parent() != tree.get_root():
		item_clicked.emit(item)


func _on_button_clicked(
	item: TreeItem, column: int, id: int, mouse_button_index: int
) -> void:
	if column != COL_BUTTONS or mouse_button_index != MOUSE_BUTTON_LEFT: return
	
	if id == MENU_BUTTON_ID:
		_open_context_menu(item)
		return
	
	if item.get_parent() == tree.get_root():
		# Group items only have the create button
		create_clicked.emit(item)
	else:
		button_clicked.emit(item, id)


func _on_item_mouse_selected(pos: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index != MOUSE_BUTTON_RIGHT: return
	
	var item := tree.get_item_at_position(pos)
	if not item: return
	# Group headers (direct children of the hidden root) have no context menu
	if item.get_parent() == tree.get_root(): return
	
	_open_context_menu(item)


func _open_context_menu(item: TreeItem) -> void:
	_context_item = item
	_build_context_menu(item)
	# PopupMenu is a Window whose position is in screen coordinates, so we must pass the mouse
	# position in screen coordinates explicitly. Calling popup() with no args uses the viewport
	# mouse position, which for editor docks is wrong and makes the menu appear at the top-left
	# corner of the screen instead of under the cursor.
	_context_menu.popup(Rect2i(DisplayServer.mouse_get_position(), Vector2i.ZERO))


func _build_context_menu(item: TreeItem) -> void:
	_context_menu.clear()
	
	for option in _get_menu_cfg(item):
		if typeof(option) == TYPE_INT and option == MENU_SEPARATOR:
			_context_menu.add_separator()
		else:
			var idx := _context_menu.item_count
			_context_menu.add_icon_item(option.icon, option.label, option.id)
			if option.has("disabled") and option.disabled:
				_context_menu.set_item_disabled(idx, true)


func _on_context_menu_id_pressed(id: int) -> void:
	if _context_item:
		menu_item_selected.emit(_context_item, id)


#endregion

#region Virtual ####################################################################################
## Returns the list of options for the right-click context menu of [param item]. Each option is a
## Dictionary with `id`, `icon`, `label` and optional `disabled` keys, or the MENU_SEPARATOR int.
func _get_menu_cfg(item: TreeItem) -> Array:
	return []


#endregion