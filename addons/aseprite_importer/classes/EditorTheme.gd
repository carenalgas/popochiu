tool
extends Node
class_name EditorTheme


var _theme : Theme


func _init(theme : Theme) -> void:
	_theme = theme


func get_color(color_name : String, color_list := "Editor") -> Color:
	return _theme.get_color(color_name, color_list)


func get_font(font_name : String, font_list := "EditorFonts") -> Font:
	return _theme.get_font(font_name, font_list)


func get_icon(icon_name : String, icon_list := "EditorIcons") -> Texture:
	return _theme.get_icon(icon_name, icon_list)


func get_stylebox(stylebox_name : String, stylebox_list := "EditorStyles") -> StyleBox:
	return _theme.get_stylebox(stylebox_name, stylebox_list)
