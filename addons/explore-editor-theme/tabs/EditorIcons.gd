tool
extends MarginContainer

signal filesystem_changed()

# Node references
onready var filter_tool : Control = $Layout/Toolbar/Filter
onready var type_tool : Control = $Layout/Toolbar/Type
onready var icon_list : ItemList = $Layout/IconView/IconList

onready var empty_panel : Control = $Layout/IconView/EmptyPanel
onready var icon_panel : Control = $Layout/IconView/IconPanel
onready var icon_preview : TextureRect = $Layout/IconView/IconPanel/IconPreview
onready var icon_preview_info : Label = $Layout/IconView/IconPanel/IconPreview/IconPreviewInfo
onready var icon_title : Label = $Layout/IconView/IconPanel/IconName
onready var icon_code : Control = $Layout/IconView/IconPanel/IconCode
onready var icon_saver : VBoxContainer = $Layout/IconView/IconPanel/IconSaver

# Private properties
var _icon_map : Dictionary = {}
var _default_type_name : String = "EditorIcons"

func _ready() -> void:
	_update_theme()
	
	_icon_map[_default_type_name] = []
	type_tool.add_text_item(_default_type_name)
	
	filter_tool.connect("text_changed", self, "_on_filter_text_changed")
	type_tool.connect("item_selected", self, "_on_type_item_selected")
	icon_list.connect("item_selected", self, "_on_icon_item_selected")
	icon_saver.connect("filesystem_changed", self, "emit_signal", ["filesystem_changed"])

func _update_theme() -> void:
	if (!is_inside_tree() || !Engine.editor_hint):
		return
	
	icon_preview_info.add_color_override("font_color", get_color("contrast_color_2", "Editor"))
	icon_title.add_font_override("font", get_font("title", "EditorFonts"))

func add_icon_set(icon_names : PoolStringArray, type_name : String) -> void:
	if (icon_names.size() == 0 || type_name.empty()):
		return
	
	if (!_icon_map.has(type_name)):
		type_tool.add_text_item(type_name)
	
	var sorted_icon_names = Array(icon_names)
	sorted_icon_names.sort()
	_icon_map[type_name] = sorted_icon_names
	
	_refresh_icon_list()

func _refresh_icon_list() -> void:
	icon_list.clear()
	
	var prefix = filter_tool.filter_text
	var type_name = type_tool.get_selected_text()
	for icon in _icon_map[type_name]:
		if (!prefix.empty() && icon.findn(prefix) < 0):
			continue
		
		icon_list.add_item(icon, get_icon(icon, type_name))

# Events
func _on_filter_text_changed(value : String) -> void:
	_refresh_icon_list()

func _on_type_item_selected(value : int) -> void:
	_refresh_icon_list()

func _on_icon_item_selected(item_index : int) -> void:
	var icon_texture = icon_list.get_item_icon(item_index)
	var icon_name = icon_list.get_item_text(item_index)
	var type_name = type_tool.get_selected_text()
	
	icon_preview.texture = icon_texture
	icon_title.text = icon_name
	icon_code.code_text = "get_icon(\"" + icon_name + "\", \"" + type_name + "\")"
	
	icon_saver.icon_name = icon_name
	icon_saver.type_name = type_name
	
	if (!icon_panel.visible):
		empty_panel.hide()
		icon_panel.show()
