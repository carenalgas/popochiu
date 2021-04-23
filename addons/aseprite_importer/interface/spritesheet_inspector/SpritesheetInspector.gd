tool
extends Container


onready var header : HBoxContainer= $Header
onready var filename_label : Label = header.find_node("Filename")
onready var settings_button : Button = header.find_node("SettingsButton")

onready var body : Container = $Body
onready var warning_message : Label = body.find_node("WarningMessage")
onready var search_file_button : Button = body.find_node("SearchFileButton")

onready var spritesheet_view : Container = body.find_node("SpritesheetView")

onready var settings_menu : Container = body.get_node("SettingsMenu")

onready var footer : HBoxContainer = $Footer
onready var frame_count : Label = footer.get_node("FrameCount")
onready var zoom_button : Button = footer.get_node("ZoomButton")
onready var zoom_slider : HSlider = footer.get_node("ZoomSlider")

onready var file_dialog : FileDialog = $FileDialog


const MSG_MISSING_IMAGE_PARAMETER = "The imported JSON doesn't contain the spritesheet file name"
const MSG_IMPORT_JSON = "Import a Aseprite JSON file to \npreview the spritesheet"
const MSG_INVALID_TEXTURE_SIZE = "The selected texture size %s doesn't match the JSON %s"
const MSG_LOAD_ERROR = "Error on loading the file!"
const MSG_SPRITESHEET_NOT_FOUND = "Spritesheet \"%s\" not found!"


var texture_size : Vector2 setget set_texture_size
var frames := []

var _zoom_update := false


func _ready() -> void:
	clear_texture()

	settings_button.pressed = false
	warning_message.text = MSG_IMPORT_JSON
	search_file_button.hide()
	spritesheet_view.hide()
	settings_menu.hide()

	var settings = settings_menu.settings
	spritesheet_view.load_settings(settings)

	settings_button.connect("toggled", self, "_on_SettingsButton_toggled")
	search_file_button.connect("pressed", self, "_on_SearchFileButton_pressed")
	spritesheet_view.connect("zoom_changed", self, "_on_SpritesheetInspector_zoom_changed")
	settings_menu.connect("settings_changed", self, "_on_SettingsMenu_settings_changed")
	zoom_button.connect("pressed", self, "_on_ZoomButton_pressed")
	zoom_slider.connect("value_changed", self, "_on_ZoomSlider_value_changed")
	file_dialog.connect("file_selected", self, "_on_FileDialog_file_selected")


func clear_texture() -> void:
	filename_label.text = ""
	spritesheet_view.hide()
	spritesheet_view.texture = null

	warning_message.text = MSG_IMPORT_JSON
	search_file_button.hide()

	footer.hide()


func get_state() -> Dictionary:
	var state := {}

	if spritesheet_view.texture:
		state.texture = spritesheet_view.texture
		state.zoom = spritesheet_view.zoom
		state.offset = spritesheet_view.offset

	state.warning_msg = warning_message.text
	state.search_file_button_visible =search_file_button.visible
	state.settings = settings_menu.settings

	return state


func get_texture() -> Texture:
	return spritesheet_view.texture


func load_texture(path : String) -> int:
	if not path:
		_show_find_file_prompt(MSG_MISSING_IMAGE_PARAMETER)

		return ERR_INVALID_DATA

	clear_texture()

	var split_path := path.rsplit("/", true, 1)
	var dir_path := split_path[0]
	var file_name := split_path[1]

	if file_name == "":
		_show_find_file_prompt(MSG_MISSING_IMAGE_PARAMETER)
		file_dialog.current_dir = dir_path

		return ERR_INVALID_DATA

	var file := File.new()

	if !file.file_exists(path):
		_show_find_file_prompt(MSG_SPRITESHEET_NOT_FOUND % file_name)
		file_dialog.current_dir = dir_path

		return ERR_FILE_NOT_FOUND

	var new_texture : Texture = load(path)

	if new_texture == null:
		_show_find_file_prompt(MSG_LOAD_ERROR)

		return ERR_INVALID_DATA

	var new_texture_size := new_texture.get_size()
	if new_texture_size != texture_size:
		var message := MSG_INVALID_TEXTURE_SIZE % [new_texture.get_size(), texture_size]
		_show_find_file_prompt(message)

		return ERR_INVALID_DATA

	spritesheet_view.texture = new_texture
	spritesheet_view.frames = frames
	spritesheet_view.selected_frames = []

	filename_label.text = file_name

	_update_frames_count()

	spritesheet_view.show()
	footer.show()

	return OK


func select_frames(selected_frames : Array) -> void:
	spritesheet_view.selected_frames = selected_frames


func set_state(new_state : Dictionary) -> void:
	if new_state.get("texture", false):
		spritesheet_view.texture = new_state.texture

		spritesheet_view.zoom = new_state.zoom
		spritesheet_view.offset = new_state.offset

		spritesheet_view.frames = frames
		spritesheet_view.selected_frames = new_state.get("selected_frames", [])

		filename_label.text = new_state.texture.resource_path

		_update_frames_count()

		spritesheet_view.show()
		footer.show()
	else:
		clear_texture()

	warning_message.text = new_state.get("warning_msg", MSG_IMPORT_JSON)
	search_file_button.visible = new_state.get("search_file_button_visible", (warning_message.text != MSG_IMPORT_JSON))
	settings_menu.settings = new_state.get("settings", {})


func _show_find_file_prompt(message : String) -> void:
	clear_texture()
	warning_message.text = message
	search_file_button.show()


func _update_frames_count() -> void:
	var frames_size := frames.size()

	if frames_size <= 0:
		frame_count.text = ""
		return

	frame_count.text = "%d frames" % frames_size

	var distinct_regions := []

	for frame in frames:
		var region : Dictionary = frame.frame
		var rect := Rect2(region.x, region.y, region.w, region.h)

		if distinct_regions.find(rect) == -1:
			distinct_regions.append(rect)

	var distinct_frames_size := distinct_regions.size()

	if frames_size > distinct_frames_size:
		var merged_frames_count := frames_size - distinct_frames_size

		frame_count.text += " (%d merged)" % merged_frames_count


func _update_theme(editor_theme : EditorTheme) -> void:
	settings_button.icon = editor_theme.get_icon("Tools")
	search_file_button.icon = editor_theme.get_icon("Load")
	zoom_button.icon = editor_theme.get_icon("Zoom")


# Setters and Getters
func set_texture_size(value : Vector2) -> void:
	texture_size = value


# Signal Callbacks
func _on_FileDialog_file_selected(path) -> void:
	load_texture(path)


func _on_SearchFileButton_pressed() -> void:
	file_dialog.invalidate()
	file_dialog.popup_centered_ratio(.5)


func _on_SettingsButton_toggled(button_pressed : bool) -> void:
	settings_menu.visible = button_pressed


func _on_SettingsMenu_settings_changed(settings : Dictionary) -> void:
	spritesheet_view.load_settings(settings)


func _on_SpritesheetInspector_zoom_changed(new_zoom : int) -> void:
	_zoom_update = true

	zoom_button.text = "%d X" % new_zoom
	zoom_slider.value = new_zoom

	_zoom_update = false


func _on_ZoomButton_pressed() -> void:
	zoom_slider.value = 1


func _on_ZoomSlider_value_changed(value : float) -> void:
	if not _zoom_update:
		spritesheet_view.zoom = round(value)
