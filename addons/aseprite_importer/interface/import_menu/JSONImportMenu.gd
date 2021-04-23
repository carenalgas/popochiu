tool
extends Container


onready var import_button : Button = $InputContainer/ImportButton
onready var clear_button : Button = $InputContainer/ClearButton
onready var file_dialog : FileDialog = $FileDialog
onready var alert_dialog : AcceptDialog = $AlertDialog


const IMPORT_BUTTON_DEFAULT_TEXT = "Import JSON"

const MSG_JSON_OPEN_FILE_ERROR = \
	"An error occurred while opening the file \"%s\"\n\n" + \
	"(error code: %d)"
const MSG_JSON_PARSE_ERROR = "Error parsing the file"
const MSG_INVALID_JSON_DATA = "Invalid Aseprite JSON file"
const MSG_MISSING_FRAME_TAGS = \
	"Missing animation tags data from the JSON file\n\n" + \
	"Make sure to enable the option Output->Meta->Tags when exporting the spritesheet from Aseprite"
const MSG_EMPTY_FRAME_TAGS = \
	"Animation tags not defined in the JSON file\n\n" + \
	"Add tags in the Aseprite timeline to define the frames inside each animation"


signal data_imported(import_data)
signal data_cleared


func _ready():
	clear_button.hide()

	alert_dialog.set_as_toplevel(true)

	import_button.connect("pressed", self, "_on_ImportButton_pressed")
	clear_button.connect("pressed", self, "_on_ClearButton_pressed")
	file_dialog.connect("file_selected", self, "_on_FileDialog_file_selected")


func set_json_filepath(new_filepath : String) -> void:
	if new_filepath:
		import_button.text = new_filepath
		clear_button.show()
	else:
		import_button.text = IMPORT_BUTTON_DEFAULT_TEXT
		clear_button.hide()


func _update_theme(editor_theme : EditorTheme) -> void:
	import_button.icon = editor_theme.get_icon("Load")
	clear_button.icon = editor_theme.get_icon("Clear")


#Signal Callbacks
func _on_ImportButton_pressed() -> void:
	file_dialog.invalidate()
	file_dialog.popup_centered_ratio(0.5)


func _on_ClearButton_pressed() -> void:
	set_json_filepath("")
	emit_signal("data_cleared")


func _on_FileDialog_file_selected(path : String) -> void:
	var import_data := AsepriteImportData.new()
	var error := import_data.load(path)

	if error != OK:
		var error_msg : String

		match error:
			AsepriteImportData.Error.ERR_JSON_PARSE_ERROR:
				error_msg = MSG_JSON_PARSE_ERROR
			AsepriteImportData.Error.ERR_INVALID_JSON_DATA:
				error_msg = MSG_INVALID_JSON_DATA
			AsepriteImportData.Error.ERR_MISSING_FRAME_TAGS:
				error_msg = MSG_MISSING_FRAME_TAGS
			AsepriteImportData.Error.ERR_EMPTY_FRAME_TAGS:
				error_msg = MSG_EMPTY_FRAME_TAGS
			_:
				error_msg = MSG_JSON_OPEN_FILE_ERROR % [path, error]

		set_json_filepath("")

		yield(get_tree(), "idle_frame")
		alert_dialog.dialog_text = error_msg
		alert_dialog.popup_centered()
	else:
		set_json_filepath(path)

		emit_signal("data_imported", import_data)
