tool
extends MarginContainer

# Private properties
var _font_map : Dictionary = {}
var _default_type_name : String = "EditorFonts"

# Node references
onready var filter_tool : Control = $Layout/Toolbar/Filter
onready var type_tool : Control = $Layout/Toolbar/Type
onready var sample_tool : Control = $Layout/Toolbar/Sample
onready var font_list : Control = $Layout/FontView/ScrollContainer/FontList

onready var empty_panel : Control = $Layout/FontView/EmptyPanel
onready var font_panel : Control = $Layout/FontView/FontPanel
onready var font_preview : Label = $Layout/FontView/FontPanel/FontPreview
onready var font_title : Label = $Layout/FontView/FontPanel/FontName
onready var font_code : Control = $Layout/FontView/FontPanel/FontCode
onready var font_inspector : Control = $Layout/FontView/FontPanel/FontInspector

# Scene references
var font_item_scene = preload("res://addons/explore-editor-theme/lists/FontListItem.tscn")

func _ready() -> void:
	_update_theme()
	
	_font_map[_default_type_name] = []
	type_tool.add_text_item(_default_type_name)
	
	filter_tool.connect("text_changed", self, "_on_filter_text_changed")
	type_tool.connect("item_selected", self, "_on_type_item_selected")
	sample_tool.connect("text_changed", self, "_on_sample_text_changed")

func _update_theme() -> void:
	if (!is_inside_tree() || !Engine.editor_hint):
		return
	
	font_preview.add_color_override("font_color", get_color("accent_color", "Editor"))
	font_title.add_font_override("font", get_font("title", "EditorFonts"))

func add_font_set(font_names : PoolStringArray, type_name : String) -> void:
	if (font_names.size() == 0 || type_name.empty()):
		return
	
	if (!_font_map.has(type_name)):
		type_tool.add_text_item(type_name)
	
	var sorted_font_names = Array(font_names)
	sorted_font_names.sort()
	_font_map[type_name] = sorted_font_names
	
	_refresh_font_list()

func _refresh_font_list() -> void:
	var font_list_items = font_list.get_children()
	for font_item in font_list_items:
		font_list.remove_child(font_item)
		font_item.disconnect("item_selected", self, "_on_font_item_selected")
		font_item.queue_free()
	
	var prefix = filter_tool.filter_text
	var type_name = type_tool.get_selected_text()
	var sample = sample_tool.sample_text
	for font in _font_map[type_name]:
		if (!prefix.empty() && font.findn(prefix) < 0):
			continue
		
		var font_item = font_item_scene.instance()
		font_item.font_name = font
		font_item.type_name = type_name
		font_item.sample_text = sample
		font_list.add_child(font_item)
		font_item.connect("item_selected", self, "_on_font_item_selected", [ font_item ])

# Events
func _on_filter_text_changed(value : String) -> void:
	_refresh_font_list()

func _on_type_item_selected(value : int) -> void:
	_refresh_font_list()

func _on_sample_text_changed(value : String) -> void:
	font_preview.text = "Sample Text" if value.empty() else value
	
	var font_list_items = font_list.get_children()
	for font_item in font_list_items:
		font_item.sample_text = value

func _on_font_item_selected(font_item : Control) -> void:
	var font_name = font_item.font_name
	var type_name = type_tool.get_selected_text()
	
	font_preview.add_font_override("font", get_font(font_name, type_name))
	font_title.text = font_name
	font_code.code_text = "get_font(\"" + font_name + "\", \"" + type_name + "\")"
	font_inspector.inspected_resource = get_font(font_name, type_name)
	
	if (!font_panel.visible):
		empty_panel.hide()
		font_panel.show()
