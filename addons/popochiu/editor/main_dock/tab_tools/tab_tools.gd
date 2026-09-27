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
# Scans all game folders for translatable files and registers them in the POT file list
# stored in ProjectSettings. This ensures the Godot POT generator knows which files to
# parse when building the translation template.
func _on_sync_translations_pressed() -> void:
	var paths := PackedStringArray()

	for folder in TRANSLATABLE_FOLDERS:
		if not DirAccess.dir_exists_absolute(folder):
			continue
		_collect_translatable_files(folder, paths)

	PopochiuConfig.sync_pot_files(paths)
	print("[Popochiu] Registered %d files for translation template generation." % paths.size())


# Opens the Project Settings window on the Localization > Template Generation tab, so the
# user can immediately generate the POT file after syncing the translation sources.
# Godot provides no API to trigger the export of POT files, so we send the user to do it
# manually. To make this UX as smooth as possible, we open the Project Settings window and
# switch to the right tab for them.
func _on_open_pot_settings_pressed() -> void:
	# NOTE: The approach is admittedly ugly. EditorInterface provides no API to open Project
	# Settings or to select a specific tab programmatically, so we are forced to traverse the
	# editor's node tree and identify tabs by their title string. On the bright side, this
	# also works when the IDE language is changed, since the title we match ("Localization")
	# is always in English regardless of editor locale.
	var settings_window := _find_project_settings_window()
	if not settings_window:
		PopochiuUtils.print_error("Could not find the Project Settings window.")
		return
	settings_window.popup_centered_ratio(0.7)
	# Wait a frame so the window fully lays out before switching tabs
	await get_tree().process_frame
	_select_localization_tab(settings_window)


# Recursively walks [param folder] and appends to [param paths] any .gd file found,
# plus .tres files that belong to the dialogs folder (which store translatable text).
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


#region Helpers ##################################################################################
# Returns the ProjectSettingsEditor window from the editor's base control children,
# or null if it has not been created yet.
func _find_project_settings_window() -> Window:
	for child in EditorInterface.get_base_control().get_children():
		if child is Window and child.get_class() == "ProjectSettingsEditor":
			return child
	return null


# Finds the top-level TabContainer inside the Project Settings window and switches it to
# the "Localization" tab, then delegates subtab selection to _select_subtab().
func _select_localization_tab(settings_window: Window) -> void:
	for tab_cnt: TabContainer in settings_window.find_children("*", "TabContainer", true, false):
		var loc_idx := _find_tab_index(tab_cnt, "Localization")
		if loc_idx < 0:
			continue
		tab_cnt.current_tab = loc_idx
		_select_subtab(tab_cnt.get_tab_control(loc_idx), "Template Generation")
		return


# Finds the first TabContainer that is a direct child of [param panel] and selects the
# tab whose title matches [param title].
func _select_subtab(panel: Control, title: String) -> void:
	for child in panel.get_children():
		if not child is TabContainer:
			continue
		var idx := _find_tab_index(child, title)
		if idx >= 0:
			child.current_tab = idx
		return


# Returns the index of the first tab in [param tab_container] whose title matches
# [param title], or -1 if no match is found.
func _find_tab_index(tab_container: TabContainer, title: String) -> int:
	for i in tab_container.get_tab_count():
		if tab_container.get_tab_title(i) == title:
			return i
	return -1


#endregion
