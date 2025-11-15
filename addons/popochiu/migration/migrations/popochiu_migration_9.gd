@tool
class_name PopochiuMigration9
extends PopochiuMigration

const VERSION = 9
const DESCRIPTION = "Replace calls to .follow_player to .follow_character(C.player"
const STEPS = [
	"Update function name in scripts"
]


#region Virtual ####################################################################################
## This is code specific for this migration. This should return [code]true[/code] if the migration
## is successful. This is called from [method do_migration] which checks to make sure the migration
## should be done before calling this.
func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			_update_function_name_in_scripts
		]
	)

#endregion


#region Private ####################################################################################

func _update_function_name_in_scripts() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = "follow_player()", to = "follow_character(C.player)"}
		], ["gui"]) else Completion.IGNORED

#endregion
