@tool
class_name PopochiuMigration11
extends PopochiuMigration

const VERSION = 11
const DESCRIPTION = "Replace deprecated E and D API calls with their current equivalents"
const STEPS = [
	"Replace deprecated E.room_readied() with R.room_readied()",
	"Replace deprecated E.rooms_states with R.rooms_states",
	"Replace deprecated E.tl property access with T singleton",
	"Replace deprecated E instance getters with C, I, and D equivalents",
	"Replace deprecated D.get_dialog_instance() with D.get_instance()",
]


#region Virtual ####################################################################################
func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			_replace_room_readied,
			_replace_rooms_states,
			_replace_tl_property,
			_replace_instance_getters,
			_replace_dialog_instance_method,
		]
	)


#endregion

#region Private ####################################################################################
## Replace E.room_readied() with its R singleton equivalent.
## Note: E.goto_room() and E.current_room were already migrated by PopochiuMigration2.
func _replace_room_readied() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = "E.room_readied(", to = "R.room_readied("},
	]) else Completion.IGNORED


## Replace E.rooms_states with its R singleton equivalent.
## Note: E.current_room was already migrated by PopochiuMigration2.
func _replace_rooms_states() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = "E.rooms_states", to = "R.rooms_states"},
	]) else Completion.IGNORED


## Replace E.tl. (method chaining on the transition layer) with the T singleton.
func _replace_tl_property() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = "E.tl.", to = "T."},
	]) else Completion.IGNORED


## Replace deprecated instance getter methods on E with their respective singleton equivalents:
## C.get_instance(), I.get_instance(), and D.get_instance().
func _replace_instance_getters() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = "E.get_character_instance(", to = "C.get_instance("},
		{from = "E.get_inventory_item_instance(", to = "I.get_instance("},
		{from = "E.get_dialog(", to = "D.get_instance("},
	]) else Completion.IGNORED


## Replace D.get_dialog_instance(), the old name for D.get_instance().
func _replace_dialog_instance_method() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = "D.get_dialog_instance(", to = "D.get_instance("},
	]) else Completion.IGNORED


#endregion
