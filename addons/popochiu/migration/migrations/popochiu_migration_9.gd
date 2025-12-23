@tool
class_name PopochiuMigration9
extends PopochiuMigration

const VERSION = 9
const DESCRIPTION = "Replace follow_player with follow_character system"
const STEPS = [
	"Update function calls in scripts from follow_player() to start_following_character(C.player)",
	"Update character scenes with follow_player flag to use follow_character property"
]


#region Virtual ####################################################################################
## This is code specific for this migration. This should return [code]true[/code] if the migration
## is successful. This is called from [method do_migration] which checks to make sure the migration
## should be done before calling this.
func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			_update_function_name_in_scripts,
			_update_character_scenes
		]
	)

#endregion


#region Private ####################################################################################

func _update_function_name_in_scripts() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = "follow_player()", to = "start_following_character(C.player)"}
	], ["gui"]) else Completion.IGNORED


## Update all character scenes that have the old follow_player flag set to true
func _update_character_scenes() -> Completion:
	var characters_path := PopochiuResources.CHARACTERS_PATH
	PopochiuUtils.print_normal("Migration %d: Updating character scenes with follow_player flag." % [VERSION])

	if not DirAccess.dir_exists_absolute(characters_path):
		PopochiuUtils.print_error("Migration %d: Characters directory does not exist: %s" % [VERSION, characters_path])
		return Completion.IGNORED

	var any_character_updated := false

	# Get all character names from popochiu_data
	var character_names := PopochiuResources.get_section_keys("characters")

	for character_name in character_names:
		var char_scene_path: String = characters_path + character_name.to_snake_case() + "/character_" + character_name.to_snake_case() + ".tscn"

		if FileAccess.file_exists(char_scene_path):
			if _update_character_by_path(char_scene_path):
				any_character_updated = true
		else:
			PopochiuUtils.print_warning("Migration %d: Character scene file does not exist: %s" % [VERSION, char_scene_path])

	PopochiuUtils.print_normal("Migration %d: Character scene update completed. %s characters were updated" % [VERSION, "Some" if any_character_updated else "No"])
	_reload_needed = any_character_updated
	return Completion.DONE if any_character_updated else Completion.IGNORED


## Update a single character scene by loading it and checking for follow_player flag
func _update_character_by_path(scene_path: String) -> bool:
	var packed_scene: PackedScene = load(scene_path)
	if not packed_scene:
		PopochiuUtils.print_error("Migration %d: Could not load packed scene: %s" % [VERSION, scene_path])
		return false

	var char_instance = packed_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	if not char_instance is PopochiuCharacter:
		PopochiuUtils.print_error("Migration %d: Scene is not a PopochiuCharacter: %s" % [VERSION, scene_path])
		char_instance.queue_free()
		return false

	# Check if the character has the old follow_player property set to true
	var needs_update := false

	if "follow_player" in char_instance and char_instance.follow_player == true:
		# Get the player character name from popochiu_data.cfg
		var player_name: String = PopochiuResources.get_data_value("setup", "pc", "")

		if player_name.is_empty():
			PopochiuUtils.print_warning(
				"Migration %d: No player character found in popochiu_data.cfg for character '%s'" %
				[VERSION, char_instance.script_name]
			)
			char_instance.queue_free()
			return false

		# Set follow_character to the player character's script_name
		char_instance.follow_character = player_name
		needs_update = true

		PopochiuUtils.print_normal(
			"Migration %d: Updated character '%s' to follow player '%s'" %
			[VERSION, char_instance.script_name, player_name]
		)

	if not needs_update:
		char_instance.queue_free()
		return false

	# Save the scene
	if PopochiuEditorHelper.pack_scene(char_instance) != OK:
		PopochiuUtils.print_error(
			"Migration %d: Couldn't update [b]%s[/b] after migrating follow_player." %
			[VERSION, char_instance.script_name]
		)
		char_instance.queue_free()
		return false

	char_instance.queue_free()
	return true

#endregion
