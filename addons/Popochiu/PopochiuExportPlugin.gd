extends EditorExportPlugin

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	var file := FileAccess.open(PopochiuResources.DATA, FileAccess.READ)
	if file:
		add_file(PopochiuResources.DATA, file.get_buffer(file.get_length()), false)
	
	file.close()
