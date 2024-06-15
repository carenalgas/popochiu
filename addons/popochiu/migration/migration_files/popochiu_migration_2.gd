@tool
class_name PopochiuMigration2
extends PopochiuMigration
## Migrates changes from Beta 1 and Beta 2 to Beta 3.
##
## This migration does the following:
## - Add a CollisionPolygon2D to each character so it can be used for scaling in PopochiuRegion.
## - Move the values defined in the old popochiu_settings.tres to the new section in
## Project Settings / Popochiu.
## - Update the dialog_menu component.
## - Update btn_dialog_speed in SimpleClick template (???).

const VERSION = 2
const DESCRIPTION = "Move settings to Project Settings and update DialogMenu component"
const STEPS = [
	"Add a [b]ScalingPolygon[/b] node to each [b]PopochiuCharacter[/b].",
	"Move popochiu_settings.tres to ProjectSettings.",
	#"",
]


#region Virtual ####################################################################################
## This is code specific for this migration. This should return [code]true[/code] if the migration
## is successful. This is called from [method do_migration] which checks to make sure the migration
## should be done before calling this.
func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			_update_characters,
			_move_settings_to_project_settings,
			#_update_dialog_menu,
		]
	)


func _update_characters() -> Completion:
	# Get the characters' .tscn files
	var file_paths := Array(PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(
		PopochiuResources.CHARACTERS_PATH,
		["tscn"]
	))
	var any_character_updated := PopochiuUtils.any(file_paths, _update_character)
	return Completion.DONE if any_character_updated else Completion.IGNORED


## Loads the [PopochiuCharacter] in [param scene_path] and add a [CollisionPolygon2D] node if it
## doesn't has a [code]ScalingPolygon[/code] child.
func _update_character(scene_path: String) -> bool:
	var popochiu_character: PopochiuCharacter = (load(scene_path) as PackedScene).instantiate()
	var was_scene_updated := false
	
	# ---- Add the ScalingPolygon node if needed ---------------------------------------------------
	if not popochiu_character.has_node("ScalingPolygon"):
		was_scene_updated = true
		var scaling_polygon := CollisionPolygon2D.new()
		scaling_polygon.name = "ScalingPolygon"
		scaling_polygon.polygon = PackedVector2Array([
			Vector2(-5, -5), Vector2(5, -5), Vector2(5, 5), Vector2(-5, 5)
		])
		popochiu_character.add_child(scaling_polygon)
		popochiu_character.move_child(scaling_polygon, 1)
		scaling_polygon.owner = popochiu_character
	
	if was_scene_updated and PopochiuEditorHelper.pack_scene(popochiu_character, scene_path) != OK:
		PopochiuUtils.print_error(
			"Couldn't update [b]%s[/b] with new voices array." % popochiu_character.script_name
		)
	
	return was_scene_updated


func _move_settings_to_project_settings() -> Completion:
	var old_settings_file := PopochiuMigrationHelper.old_settings_file
	
	if not FileAccess.file_exists(old_settings_file):
		return Completion.IGNORED
	
	var old_settings := load(old_settings_file)
	
	#max_dialog_options
	#inventory_always_visible
	#toolbar_always_visible
	
	var settings_map := {
		# ---- GUI ----------------------------------------------------------------
		"SCALE_GUI": "",
		"FADE_COLOR": "",
		"SKIP_CUTSCENE_TIME": "",
		# ---- Dialogs ------------------------------------------------------------
		"TEXT_SPEED": old_settings.text_speeds[old_settings.default_text_speed],
		"AUTO_CONTINUE_TEXT": "",
		"USE_TRANSLATIONS": "",
		# ---- Inventory ----------------------------------------------------------
		"INVENTORY_LIMIT": "",
		"ITEMS_ON_START": "",
		# ---- Pixel game ---------------------------------------------------------
		"PIXEL_ART_TEXTURES": "is_pixel_art_game",
		"PIXEL_PERFECT": "is_pixel_perfect",
	}
	for key: String in settings_map:
		PopochiuConfig.set_project_setting(
			key,
			old_settings[key.to_lower()] if key.is_empty() else settings_map[key]
		)
	
	if DirAccess.remove_absolute(old_settings_file) != OK:
		PopochiuUtils.print_error("Couldn't delete [code]%s[/code]." % old_settings_file)
		return Completion.FAILED
	
	return Completion.DONE


func _update_dialog_menu() -> Completion:
	return Completion.DONE


#endregion
