@tool
class_name PopochiuMigrationX # Change X to be the correct version number for migration
extends PopochiuMigration

# Update constant values to be correct for your migration
const VERSION = -1
const DESCRIPTION = "short description of migration goes here"
const STEPS = [
	# Include a short description of each step here
	#"Step 1"
]



#region Virtual ####################################################################################
## This is code specific for this migration. This should return [code]true[/code] if the migration
## is successful. This is called from [method do_migration] which checks to make sure the migration
## should be done before calling this.
func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			# Include the function names for each step here
			#_step1
		]
	)


func _is_reload_required() -> bool:
	return false


#endregion

#region Private ####################################################################################
#func _step1() -> Completion:
	#return Completion.DONE

#endregion
