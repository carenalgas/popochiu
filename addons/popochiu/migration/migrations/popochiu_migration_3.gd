@tool
class_name PopochiuMigration3
extends PopochiuMigration

const VERSION = 3
const DESCRIPTION = "Update clickables to set look_at_point property"
const STEPS = [
	"Update all clickables in rooms",
]
const LOOK_AT_POINT_OFFSET = Vector2(-10, -10)


#region Virtual ####################################################################################
## This is code specific for this migration. This should return [code]true[/code] if the migration
## is successful. This is called from [method do_migration] which checks to make sure the migration
## should be done before calling this.
func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			_update_objects_in_rooms
		]
	)


#endregion

#region Private ####################################################################################
## Update all rooms clickables to set a default value for the look_at_point property.
func _update_objects_in_rooms() -> Completion:
	var any_room_updated := PopochiuUtils.any_exhaustive(
		PopochiuEditorHelper.get_rooms(), _update_room
	)

	_reload_needed = any_room_updated
	return Completion.DONE if any_room_updated else Completion.IGNORED


func _update_popochiu_clickable(popochiu_room: PopochiuRoom, clickable_type: String) -> bool:
	if not popochiu_room.has_node(clickable_type):
		return false

	var changed = false

	for obj: Node in popochiu_room.find_child(clickable_type).get_children():
		if PopochiuEditorHelper.is_popochiu_clickable(obj):
			obj.look_at_point = obj.walk_to_point + LOOK_AT_POINT_OFFSET
			changed = true
			PopochiuUtils.print_normal(
				"Migration %d: %s: updated %s look_at_point." %
				[VERSION, clickable_type, obj.script_name]
			)

	return changed


func _update_room(popochiu_room: PopochiuRoom) -> bool:
	var room_updated = _update_popochiu_clickable(popochiu_room, "Characters")
	room_updated = _update_popochiu_clickable(popochiu_room, "Props") or room_updated
	room_updated = _update_popochiu_clickable(popochiu_room, "Hotspots") or room_updated
	
	if room_updated and PopochiuEditorHelper.pack_scene(popochiu_room) != OK:
		PopochiuUtils.print_error(
			"Migration %d: Couldn't update [b]%s[/b] after updating clickables." %
			[VERSION, popochiu_room.script_name]
		)

	return room_updated


#endregion
