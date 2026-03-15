@tool
class_name PopochiuMigration7
extends PopochiuMigration

const VERSION = 7
const DESCRIPTION = "Remove deprecated ASEPRITE_LOOP_ANIMATION project setting"
const STEPS = [
	"Remove the global loop animation setting from project settings",
]


#region Virtual ####################################################################################
## This is code specific for this migration. This should return [code]true[/code] if the migration
## is successful. This is called from [method do_migration] which checks to make sure the migration
## should be done before calling this.
func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			_remove_deprecated_loop_animation_setting
		]
	)


#endregion

#region Private ####################################################################################
## Remove the deprecated ASEPRITE_LOOP_ANIMATION setting from project settings.
func _remove_deprecated_loop_animation_setting() -> Completion:
	const DEPRECATED_SETTING = "popochiu/aseprite_import/loop_animation_by_default"
	
	if ProjectSettings.has_setting(DEPRECATED_SETTING):
		# Clear the setting from project settings
		ProjectSettings.clear(DEPRECATED_SETTING)
		
		# Save the project settings
		var save_result = ProjectSettings.save()
		if save_result != OK:
			PopochiuUtils.print_error(
				"Migration %d: Failed to save project settings after removing deprecated setting." %
				[VERSION]
			)
			return Completion.FAILED
		
		PopochiuUtils.print_normal(
			"Migration %d: removed deprecated setting '%s' from project settings." %
			[VERSION, DEPRECATED_SETTING]
		)
		
		return Completion.DONE
	
	# Setting was not present, nothing to do
	return Completion.IGNORED


#endregion