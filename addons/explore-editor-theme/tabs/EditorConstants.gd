tool
extends MarginContainer

# Node references
onready var filter_tool : Control = $Layout/Toolbar/Filter
onready var type_tool : Control = $Layout/Toolbar/Type
onready var constant_list : ItemList = $Layout/ConstantView/ConstantList

onready var empty_panel : Control = $Layout/ConstantView/EmptyPanel
onready var constant_panel : Control = $Layout/ConstantView/ConstantPanel
onready var constant_title : Label = $Layout/ConstantView/ConstantPanel/ConstantName
onready var constant_value : Label = $Layout/ConstantView/ConstantPanel/ConstantValue
onready var constant_code : Control = $Layout/ConstantView/ConstantPanel/ConstantCode

# Private properties
var _constant_map : Dictionary = {}
var _default_type_name : String = "Editor"

func _ready() -> void:
	_update_theme()
	
	_constant_map[_default_type_name] = []
	type_tool.add_text_item(_default_type_name)
	
	filter_tool.connect("text_changed", self, "_on_filter_text_changed")
	type_tool.connect("item_selected", self, "_on_type_item_selected")
	constant_list.connect("item_selected", self, "_on_constant_item_selected")

func _update_theme() -> void:
	if (!is_inside_tree() || !Engine.editor_hint):
		return
	
	constant_title.add_font_override("font", get_font("title", "EditorFonts"))
	constant_value.add_font_override("font", get_font("source", "EditorFonts"))
	constant_value.add_color_override("font_color", get_color("accent_color", "Editor"))

func add_constant_set(constant_names : PoolStringArray, type_name : String) -> void:
	if (constant_names.size() == 0 || type_name.empty()):
		return
	
	if (!_constant_map.has(type_name)):
		type_tool.add_text_item(type_name)
	
	var sorted_constant_names = Array(constant_names)
	sorted_constant_names.sort()
	_constant_map[type_name] = sorted_constant_names
	
	_refresh_constant_list()

func _refresh_constant_list() -> void:
	constant_list.clear()
	
	var prefix = filter_tool.filter_text
	var type_name = type_tool.get_selected_text()
	for constant in _constant_map[type_name]:
		if (!prefix.empty() && constant.findn(prefix) < 0):
			continue
		
		constant_list.add_item(constant)

# Events
func _on_filter_text_changed(value : String) -> void:
	_refresh_constant_list()

func _on_type_item_selected(value : int) -> void:
	_refresh_constant_list()

func _on_constant_item_selected(item_index : int) -> void:
	var constant_name = constant_list.get_item_text(item_index)
	var type_name = type_tool.get_selected_text()
	
	constant_title.text = constant_name
	var raw_value = get_constant(constant_name, type_name)
	constant_value.text = str(raw_value) + " (" + str(bool(raw_value)) + ")"
	constant_code.code_text = "get_constant(\"" + constant_name + "\", \"" + type_name + "\")"
	
	if (!constant_panel.visible):
		empty_panel.hide()
		constant_panel.show()
