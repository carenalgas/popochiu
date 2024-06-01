@tool
class_name PopochiuMigration3
extends PopochiuMigration
## Migrates changes from Beta 3 to 2.0 release.
##
## This migration does the following:
## - Remove BaselineHelper, WalkToHelper nodes in PopochiuClickable scenes.
## - Remove DialogPos node in PopochiuCharacter scenes.
## - Update calls to old methods in E to the new ones (mostly now in R).

const VERSION = 3
const DESCRIPTION = "Remove helper nodes in PopochiuClickable objects, replace deprecated calls to\
 methods in E."


#region Virtual ####################################################################################
## This is code specific for this migration. This should return [code]true[/code] if the migration
## is successful. This is called from [method do_migration] which checks to make sure the migration
## should be done before calling this.
func _do_migration() -> bool:
	PopochiuUtils.print_normal("Soy la migración 3 y no estoy lista...")
	await PopochiuEditorHelper.wait_process_frame()
	return false


#endregion
