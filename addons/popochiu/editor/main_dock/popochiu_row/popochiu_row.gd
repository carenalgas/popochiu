@tool
extends HBoxContainer
## The row that is created for Rooms, Characters, Inventory items, Dialogs, Props, Hotspots, Regions,
## Walkable areas, and Markers in the dock.

signal clicked(node: HBoxContainer)

enum MenuOptions {
	SEPARATOR = -1,
	DELETE,
}

const SELECTED_FONT_COLOR = Color("706deb")
const AudioCue = preload("res://addons/popochiu/engine/audio_manager/audio_cue.gd")

var path := ""
var is_menu_hidden := false
var type := -1

var _delete_dialog: PopochiuEditorHelper.DeleteConfirmation = null

@onready var label: Label = %Label
@onready var tag: TextureRect = %Tag
@onready var btn_menu: MenuButton = %BtnMenu
@onready var menu_popup: PopupMenu = btn_menu.get_popup()
@onready var buttons_container: HBoxContainer = %ButtonsContainer
@onready var dflt_font_color: Color = label.get_theme_color("font_color")


#region Godot ######################################################################################
func _ready() -> void:
	label.text = str(name)
	tooltip_text = path
	
	# Assign icons
	btn_menu.icon = get_theme_icon("GuiTabMenuHl", "EditorIcons")
	
	# Create the context menu based checked the type of Object this row represents
	_create_menu()
	
	tag.hide()
	if is_menu_hidden:
		btn_menu.hide()
	
	gui_input.connect(_check_click)
	menu_popup.id_pressed.connect(_menu_item_pressed)


#endregion

#region Virtual ####################################################################################
func _remove_object() -> void:
	pass


func _clear_tag() -> void:
	pass


#endregion

#region Public #####################################################################################
func select() -> void:
	label.add_theme_color_override("font_color", SELECTED_FONT_COLOR)
	clicked.emit(self)


func deselect() -> void:
	label.add_theme_color_override("font_color", dflt_font_color)


func remove_menu_option(opt: int) -> void:
	menu_popup.remove_item(menu_popup.get_item_index(opt))


func add_button(btn: Button) -> void:
	buttons_container.add_child(btn)


func clear_tag() -> void:
	if tag.visible:
		tag.visible = false
		_clear_tag()


#endregion

#region Private ####################################################################################
func _create_menu() -> void:
	menu_popup.clear()
	
	for option in _get_menu_cfg():
		if typeof(option) == TYPE_INT and option == MenuOptions.SEPARATOR:
			menu_popup.add_separator("", MenuOptions.SEPARATOR)
		elif not option.has("types") or (option.has("types") and type in option.types):
			menu_popup.add_icon_item(option.icon, option.label, option.id)
	
	if menu_popup.item_count == 2:
		menu_popup.remove_item(menu_popup.get_item_index(MenuOptions.SEPARATOR))


func _get_menu_cfg() -> Array:
	return [
		MenuOptions.SEPARATOR,
		{
			id = MenuOptions.DELETE,
			icon = get_theme_icon("Remove", "EditorIcons"),
			label = "Remove"
		}
	]


func _check_click(event: InputEvent) -> void:
	if PopochiuUtils.get_click_or_touch_index(event) == MOUSE_BUTTON_LEFT:
		EditorInterface.select_file(path)
		select()


func _menu_item_pressed(id: int) -> void:
	match id:
		MenuOptions.DELETE:
			_remove_object()


#endregion
