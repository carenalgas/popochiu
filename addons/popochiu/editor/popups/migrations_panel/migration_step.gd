@tool
extends HBoxContainer

@onready var check_box: CheckBox = $CheckBox
@onready var description: RichTextLabel = $Description
@onready var progress: TextureRect = $Progress


#region Godot ######################################################################################
func _ready() -> void:
	PopochiuEditorHelper.override_font(description, "normal_font", "output_source")
	PopochiuEditorHelper.override_font(description, "bold_font", "output_source_bold")
	PopochiuEditorHelper.override_font(description, "italics_font", "output_source_italic")
	progress.hide()


#endregion

#region Public #####################################################################################
func start() -> void:
	var idx := 1
	progress.visible = true
	while progress.visible:
		progress.texture = get_theme_icon("Progress%d" % idx, "EditorIcons")
		await PopochiuEditorHelper.secs_passed(0.1)
		
		idx = wrapi(idx + 1, 1, 9)


func stop() -> void:
	progress.visible = false


#endregion
