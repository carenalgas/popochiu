tool
extends MarginContainer

# Public properties
export var preview_background_texture : Texture

# Private properties
var _stylebox_map : Dictionary = {}
var _default_type_name : String = "EditorStyles"

# Node references
onready var filter_tool : Control = $Layout/Toolbar/Filter
onready var type_tool : Control = $Layout/Toolbar/Type
onready var stylebox_list : Control = $Layout/StyleboxView/ScrollContainer/StyleboxList

onready var empty_panel : Control = $Layout/StyleboxView/EmptyPanel
onready var stylebox_panel : Control = $Layout/StyleboxView/StyleboxPanel
onready var stylebox_preview : Panel = $Layout/StyleboxView/StyleboxPanel/StyleboxPreview/StyleboxPreviewPanel
onready var preview_background : TextureRect = $Layout/StyleboxView/StyleboxPanel/StyleboxPreview/PreviewBackground
onready var stylebox_title : Label = $Layout/StyleboxView/StyleboxPanel/StyleboxName
onready var stylebox_code : Control = $Layout/StyleboxView/StyleboxPanel/StyleboxCode
onready var stylebox_inspector : Control = $Layout/StyleboxView/StyleboxPanel/StyleboxInspector

# Scene references
var stylebox_item_scene = preload("res://addons/explore-editor-theme/lists/StyleboxListItem.tscn")

func _ready() -> void:
	_update_theme()
	_update_preview_background()
	
	_stylebox_map[_default_type_name] = []
	type_tool.add_text_item(_default_type_name)
	
	filter_tool.connect("text_changed", self, "_on_filter_text_changed")
	type_tool.connect("item_selected", self, "_on_type_item_selected")

func _update_theme() -> void:
	if (!is_inside_tree() || !Engine.editor_hint):
		return
	
	stylebox_preview.add_color_override("font_color", get_color("accent_color", "Editor"))
	stylebox_title.add_font_override("font", get_font("title", "EditorFonts"))

func _update_preview_background() -> void:
	var bg_image = preview_background_texture.get_data()
	bg_image.expand_x2_hq2x()
	var bg_texture = ImageTexture.new()
	bg_texture.create_from_image(bg_image)
	preview_background.texture = bg_texture

func add_stylebox_set(stylebox_names : PoolStringArray, type_name : String) -> void:
	if (stylebox_names.size() == 0 || type_name.empty()):
		return
	
	if (!_stylebox_map.has(type_name)):
		type_tool.add_text_item(type_name)
	
	var sorted_stylebox_names = Array(stylebox_names)
	sorted_stylebox_names.sort()
	_stylebox_map[type_name] = sorted_stylebox_names
	
	_refresh_stylebox_list()

func _refresh_stylebox_list() -> void:
	var stylebox_list_rows = stylebox_list.get_children()
	for stylebox_row in stylebox_list_rows:
		stylebox_list.remove_child(stylebox_row)
		
		var stylebox_list_items = stylebox_row.get_children()
		for stylebox_item in stylebox_list_items:
			stylebox_item.disconnect("item_selected", self, "_on_stylebox_item_selected")
		
		stylebox_row.queue_free()
	
	var prefix = filter_tool.filter_text
	var type_name = type_tool.get_selected_text()
	var item_index = 0
	var horizontal_container = HBoxContainer.new()
	for stylebox in _stylebox_map[type_name]:
		if (!prefix.empty() && stylebox.findn(prefix) < 0):
			continue
		
		var stylebox_item = stylebox_item_scene.instance()
		stylebox_item.stylebox_name = stylebox
		stylebox_item.type_name = type_name
		stylebox_item.size_flags_horizontal = SIZE_EXPAND_FILL
		horizontal_container.add_child(stylebox_item)
		
		stylebox_item.connect("item_selected", self, "_on_stylebox_item_selected", [ stylebox_item ])
		item_index += 1
		if (item_index % 4 == 0):
			stylebox_list.add_child(horizontal_container)
			horizontal_container = HBoxContainer.new()
		
	if (horizontal_container.get_child_count() > 0):
		stylebox_list.add_child(horizontal_container)

# Handlers
func _on_filter_text_changed(value : String) -> void:
	_refresh_stylebox_list()

func _on_type_item_selected(value : int) -> void:
	_refresh_stylebox_list()

func _on_stylebox_item_selected(stylebox_item : Control) -> void:
	var stylebox_name = stylebox_item.stylebox_name
	var type_name = type_tool.get_selected_text()
	
	stylebox_title.text = stylebox_name
	stylebox_preview.add_stylebox_override("panel", get_stylebox(stylebox_name, type_name))
	stylebox_code.code_text = "get_stylebox(\"" + stylebox_name + "\", \"" + type_name + "\")"
	stylebox_inspector.inspected_resource = get_stylebox(stylebox_name, type_name)
	
	if (!stylebox_panel.visible):
		empty_panel.hide()
		stylebox_panel.show()
