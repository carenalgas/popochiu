tool
extends MarginContainer

# Public properties
export var color_icon_background : Texture

# Private properties
var _color_map : Dictionary = {}
var _default_type_name : String = "Editor"

# Node references
onready var filter_tool : Control = $Layout/Toolbar/Filter
onready var type_tool : Control = $Layout/Toolbar/Type
onready var color_list : ItemList = $Layout/ColorView/ColorList

onready var empty_panel : Control = $Layout/ColorView/EmptyPanel
onready var color_panel : Control = $Layout/ColorView/ColorPanel
onready var color_preview : TextureRect = $Layout/ColorView/ColorPanel/ColorPreview
onready var color_preview_info : Label = $Layout/ColorView/ColorPanel/ColorPreview/ColorPreviewInfo
onready var color_title : Label = $Layout/ColorView/ColorPanel/ColorName
onready var color_code : Control = $Layout/ColorView/ColorPanel/ColorCode

func _ready() -> void:
	_update_theme()
	
	_color_map[_default_type_name] = []
	type_tool.add_text_item(_default_type_name)
	
	filter_tool.connect("text_changed", self, "_on_filter_text_changed")
	type_tool.connect("item_selected", self, "_on_type_item_selected")
	color_list.connect("item_selected", self, "_on_color_item_selected")

func _update_theme() -> void:
	if (!is_inside_tree() || !Engine.editor_hint):
		return
	
	color_preview_info.add_color_override("font_color", get_color("contrast_color_2", "Editor"))
	color_title.add_font_override("font", get_font("title", "EditorFonts"))

func add_color_set(color_names : PoolStringArray, type_name : String) -> void:
	if (color_names.size() == 0 || type_name.empty()):
		return
	
	if (!_color_map.has(type_name)):
		type_tool.add_text_item(type_name)
	
	var sorted_color_names = Array(color_names)
	sorted_color_names.sort()
	_color_map[type_name] = sorted_color_names
	
	_refresh_color_list()

func _refresh_color_list() -> void:
	color_list.clear()
	
	var prefix = filter_tool.filter_text
	var type_name = type_tool.get_selected_text()
	var item_index = 0
	for color in _color_map[type_name]:
		if (!prefix.empty() && color.findn(prefix) < 0):
			continue
		
		color_list.add_item(color, color_icon_background)
		color_list.set_item_icon_modulate(item_index, get_color(color, type_name))
		item_index += 1

# Events
func _on_filter_text_changed(value : String) -> void:
	_refresh_color_list()

func _on_type_item_selected(value : int) -> void:
	_refresh_color_list()

func _on_color_item_selected(item_index : int) -> void:
	var color_texture = color_list.get_item_icon(item_index)
	var color_modulate = color_list.get_item_icon_modulate(item_index)
	var color_name = color_list.get_item_text(item_index)
	var type_name = type_tool.get_selected_text()
	
	color_preview.texture = color_texture
	color_preview.self_modulate = color_modulate
	color_preview_info.text = "R: " + str(color_modulate.r) + "\n"
	color_preview_info.text += "G: " + str(color_modulate.g) + "\n"
	color_preview_info.text += "B: " + str(color_modulate.b) + "\n"
	color_preview_info.text += "A: " + str(color_modulate.a) + ""
	color_title.text = color_name
	color_code.code_text = "get_color(\"" + color_name + "\", \"" + type_name + "\")"
	
	if (!color_panel.visible):
		empty_panel.hide()
		color_panel.show()
