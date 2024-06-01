@tool
class_name PopochiuMigration2
extends PopochiuMigration
## Migrates changes from Beta 1 and Beta 2 to Beta 3.
##
## This migration does the following:
## - Update how voices are now defined in PopochiuCharacter
## - Move the values defined in the old popochiu_settings.tres to the new section in
## Project Settings / Popochiu
## - Update the dialog_menu component.
## - Update btn_dialog_speed in SimpleClick template (???).

const VERSION = 2
const DESCRIPTION = "Move settings to Project Settings and update DialogMenu component"


#region Virtual ####################################################################################
## This is code specific for this migration. This should return [code]true[/code] if the migration
## is successful. This is called from [method do_migration] which checks to make sure the migration
## should be done before calling this.
func _do_migration() -> bool:
	PopochiuUtils.print_normal("Soy la migración 2 y no estoy lista...")
	await PopochiuEditorHelper.wait_process_frame()
	return false


#endregion
