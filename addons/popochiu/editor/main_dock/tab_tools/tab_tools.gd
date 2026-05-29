@tool
extends VBoxContainer

# Paths to scan for translatable scripts (rooms include props/hotspots as subfolders)
const TRANSLATABLE_FOLDERS: PackedStringArray = [
	PopochiuResources.ROOMS_PATH,
	PopochiuResources.CHARACTERS_PATH,
	PopochiuResources.INVENTORY_ITEMS_PATH,
	PopochiuResources.DIALOGS_PATH,
]

@onready var btn_sync_translations: Button = %BtnSyncTranslations


#region Godot ######################################################################################
func _ready() -> void:
	btn_sync_translations.pressed.connect(_on_sync_translations_pressed)


#endregion

#region Private ####################################################################################
func _on_sync_translations_pressed() -> void:
	var paths := PackedStringArray()

	for folder in TRANSLATABLE_FOLDERS:
		if not DirAccess.dir_exists_absolute(folder):
			continue
		_collect_translatable_files(folder, paths)

	PopochiuConfig.sync_pot_files(paths)
	print("[Popochiu] Registered %d files for translation template generation." % paths.size())


func _collect_translatable_files(folder: String, paths: PackedStringArray) -> void:
	var dir := DirAccess.open(folder)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var full_path := folder.path_join(file_name)
		if dir.current_is_dir():
			_collect_translatable_files(full_path, paths)
		else:
			var ext := file_name.get_extension()
			if ext == "gd":
				paths.append(full_path)
			elif ext == "tres" and folder.begins_with(PopochiuResources.DIALOGS_PATH):
				paths.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()


#endregion
