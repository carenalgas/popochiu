tool
extends EditorPlugin

var gpl_file_setting_key : String = "fc/colorpicker_palette/gpl_file"
var colors_setting_key : String = "fc/colorpicker_palette/colors"

var colors : PoolColorArray

func _create_colors_property():
	ProjectSettings.set(colors_setting_key, PoolColorArray())

	var property_info = {
		"name": colors_setting_key,
		"type": TYPE_COLOR_ARRAY,
	}

	ProjectSettings.add_property_info(property_info)
	ProjectSettings.set_initial_value(colors_setting_key, PoolColorArray())

func _create_gpl_file_property():
	ProjectSettings.set(gpl_file_setting_key, '')

	var property_info = {
		"name": gpl_file_setting_key,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.gpl",
	}

	ProjectSettings.add_property_info(property_info)
	ProjectSettings.set_initial_value(gpl_file_setting_key, '')

func _enter_tree():
	
	if ! ProjectSettings.has_setting(colors_setting_key):
		_create_colors_property()
	
	if ! ProjectSettings.has_setting(gpl_file_setting_key):
		_create_gpl_file_property()
	
	var gpl_file_path = ProjectSettings.get_setting(gpl_file_setting_key)
	
	if gpl_file_path:
		print("FC ColorPicker Palette: Using %s as palette file." % gpl_file_path)
		colors.append_array(_import_gpl(gpl_file_path))
	
	var manual_colors = ProjectSettings.get_setting(colors_setting_key) as PoolColorArray
	if manual_colors:
		colors.append_array(manual_colors)

	if colors:
		var ep = EditorPlugin.new()
		ep.get_editor_interface() \
			.get_editor_settings() \
			.set_project_metadata("color_picker", "presets", colors)
		ep.free()
		
		print("FC ColorPicker Palette: Loaded %s colors as ColorPicker presets." % colors.size())

func _exit_tree():
	pass

func _import_gpl(path : String) -> PoolColorArray:
	var color_line_regex = RegEx.new()
	color_line_regex.compile("(?<red>[0-9]{1,3})[ \t]+(?<green>[0-9]{1,3})[ \t]+(?<blue>[0-9]{1,3})")

	var colors = PoolColorArray()

	var file = File.new()
	if file.file_exists(path):
		file.open(path, File.READ)
		var text = file.get_as_text()
		var lines = text.split('\n')
		var line_number := 0
		
		for line in lines:
			line = line.lstrip(" ")

			if line_number == 0:
				if line != "GIMP Palette":
					push_error("File \"%s\" is not a valid GIMP Palette." % path)
					break

			elif !line.begins_with('#') and !line.empty():
				var matches = color_line_regex.search(line)
				if matches:
					var red: float = matches.get_string("red").to_float() / 255.0
					var green: float = matches.get_string("green").to_float() / 255.0
					var blue: float = matches.get_string("blue").to_float() / 255.0
					var color = Color(red, green, blue)
					colors.append(color)
				else:
					push_error("Unable to parse line %s with content: %s" % [line_number + 1, line])

			line_number += 1

		file.close()
	else:
		push_error("File \"%s\" does not exist." % path)

	return colors
