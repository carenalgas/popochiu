extends EditorExportPlugin

func _export_begin(features: PoolStringArray, is_debug: bool, path: String, flags: int) -> void:
	var file = File.new()
	
	if file.open(PopochiuResources.DATA, File.READ) == OK:
		add_file(PopochiuResources.DATA, file.get_buffer(file.get_len()), false)
	file.close()
