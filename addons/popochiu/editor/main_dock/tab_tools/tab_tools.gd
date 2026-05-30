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
@onready var btn_open_pot_settings: Button = %BtnOpenPotSettings


#region Godot ######################################################################################
func _ready() -> void:
	btn_sync_translations.pressed.connect(_on_sync_translations_pressed)
	btn_open_pot_settings.pressed.connect(_on_open_pot_settings_pressed)


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


func _on_open_pot_settings_pressed() -> void:
	var base := EditorInterface.get_base_control()
	for child in base.get_children():
		if child is Window and child.get_class() == "ProjectSettingsEditor":
			child.popup_centered_ratio(0.7)
			# Wait a frame so the window fully lays out before switching tabs
			await get_tree().process_frame
			_select_localization_tab(child)
			return
	PopochiuUtils.print_error("Could not find the Project Settings window.")


func _select_localization_tab(settings_window: Window) -> void:
	# Find the main TabContainer (the one that has a "Localization" tab)
	var tab_containers := settings_window.find_children("*", "TabContainer", true, false)
	for tab_container: TabContainer in tab_containers:
		for i in tab_container.get_tab_count():
			if tab_container.get_tab_title(i) == "Localization":
				tab_container.current_tab = i
				# Find the sub-tab container within the Localization panel
				var localization_panel := tab_container.get_tab_control(i)
				for sub_child in localization_panel.get_children():
					if sub_child is TabContainer:
						for j in sub_child.get_tab_count():
							if sub_child.get_tab_title(j) == "Template Generation":
								sub_child.current_tab = j
								break
						break
				return


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
