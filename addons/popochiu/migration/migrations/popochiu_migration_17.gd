@tool
class_name PopochiuMigration17
extends PopochiuMigration

const VERSION = 17
const DESCRIPTION = "Migrate inventory checks to per-character inventory"
const STEPS = [
	"Update unambiguous player inventory checks",
	"Update copied GUI inventory hook signatures",
	"Report inventory code that needs manual migration",
]

const LEGACY_PATTERNS := [
	"I.items",
	"PopochiuUtils.i.items",
	r"I\.[A-Za-z_]\w*\.in_inventory\b",
	"in_inventory\\s*=",
	"I\\.add_item\\(",
	"I\\.remove_item\\(",
	"func _on_item_added(item: PopochiuInventoryItem) -> void:",
	"func _on_item_removed(item: PopochiuInventoryItem) -> void:",
	"func _on_item_replaced(item: PopochiuInventoryItem, new_item: PopochiuInventoryItem) -> void:",
]


#region Virtual ####################################################################################
func _is_migration_needed() -> bool:
	return not _get_game_scripts_with_legacy_inventory_code().is_empty()


func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			_migrate_player_inventory_checks,
			_migrate_gui_inventory_hooks,
			_report_legacy_inventory_code,
		]
	)


#endregion

#region Private ####################################################################################
## Converts the old, player-only ownership check to the explicit player API.
## This is safe because the old I.Item.in_inventory API always targeted the player character.
func _migrate_player_inventory_checks() -> Completion:
	var replacements: Array[Dictionary] = []
	replacements.assign([
		{
			pattern = r"I\.([A-Za-z_]\w*)\.in_inventory\b",
			to = "C.player.has_inventory_item(\"$1\")",
		},
	])
	var folders_to_ignore: Array[String] = []
	folders_to_ignore.assign(["autoloads"])
	var replaced := PopochiuMigrationHelper.replace_regex_in_scripts(
		replacements, folders_to_ignore
	)
	return Completion.DONE if replaced else Completion.IGNORED


## Updates hooks copied from older GUI templates to the per-character signatures.
func _migrate_gui_inventory_hooks() -> Completion:
	var replacements: Array[Dictionary] = []
	replacements.assign([
		{
			pattern = r"func _on_item_added\(item: PopochiuInventoryItem\) -> void:",
			to = "func _on_item_added(item: PopochiuInventoryItem, _character: PopochiuCharacter) -> void:",
		},
		{
			pattern = r"func _on_item_removed\(item: PopochiuInventoryItem\) -> void:",
			to = "func _on_item_removed(item: PopochiuInventoryItem, _character: PopochiuCharacter) -> void:",
		},
		{
			pattern = r"func _on_item_replaced\(item: PopochiuInventoryItem, new_item: PopochiuInventoryItem\) -> void:",
			to = "func _on_item_replaced(item: PopochiuInventoryItem, new_item: PopochiuInventoryItem, _character: PopochiuCharacter) -> void:",
		},
		{
			pattern = r"await super\(item\)",
			to = "await super(item, _character)",
		},
		{
			pattern = r"await super\(item, new_item\)",
			to = "await super(item, new_item, _character)",
		},
	])
	var folders_to_ignore: Array[String] = []
	folders_to_ignore.assign(["autoloads"])
	var replaced := PopochiuMigrationHelper.replace_regex_in_scripts(
		replacements, folders_to_ignore
	)
	return Completion.DONE if replaced else Completion.IGNORED


## Reports patterns whose target character or intended side effects cannot be inferred safely.
func _report_legacy_inventory_code() -> Completion:
	var matches := _get_game_scripts_with_legacy_inventory_code()
	if matches.is_empty():
		return Completion.IGNORED

	var files_list := ""
	for file_path: String in matches:
		files_list += "\n- %s" % file_path

	PopochiuUtils.print_warning(
		"Migration %d: Found inventory code that requires manual migration:%s\n" % [
			VERSION, files_list
		]
		+ "I.items and direct in_inventory assignments no longer identify a "
		+ "character reliably. Use C.player.inventory or the character inventory API "
		+ "and pass the target character explicitly when needed."
	)
	return Completion.DONE


func _get_game_scripts_with_legacy_inventory_code() -> Array[String]:
	var script_paths := PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(
		PopochiuResources.GAME_PATH, ["gd"], ["autoloads"]
	)
	var matching_files: Array[String] = []

	for file_path: String in script_paths:
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			continue
		var content := file.get_as_text()
		file.close()

		for pattern: String in LEGACY_PATTERNS:
			var regex := RegEx.new()
			if regex.compile(pattern) == OK and regex.search(content):
				matching_files.append(file_path)
				break

	return matching_files


#endregion
