@tool
class_name PopochiuMigration5
extends PopochiuMigration

const VERSION = 5
const DESCRIPTION = "Make Marker2D nodes invisible in all rooms"
const STEPS = [
    "Update all markers in rooms to support new gizmos",
]


#region Virtual ####################################################################################
## This is code specific for this migration. This should return [code]true[/code] if the migration
## is successful. This is called from [method do_migration] which checks to make sure the migration
## should be done before calling this.
func _do_migration() -> bool:
    return await PopochiuMigrationHelper.execute_migration_steps(
        self,
        [
            _update_markers_in_rooms
        ]
    )


#endregion

#region Private ####################################################################################
## Update all rooms' Marker2D nodes to be invisible
func _update_markers_in_rooms() -> Completion:
    var any_room_updated := PopochiuUtils.any_exhaustive(
        PopochiuEditorHelper.get_rooms(), _update_room
    )

    _reload_needed = any_room_updated
    return Completion.DONE if any_room_updated else Completion.IGNORED


func _update_room(popochiu_room: PopochiuRoom) -> bool:
    # Check if the room has a Markers node
    if not popochiu_room.has_node("Markers"):
        return false

    var markers_node = popochiu_room.get_node("Markers")
    var changed = false
    
    # Check all children of the Markers node
    for marker in markers_node.get_children():
        if marker is Marker2D:
            marker.visible = false
            changed = true
            PopochiuUtils.print_normal(
                "Migration %d: made marker '%s' in room '%s' invisible." %
                [VERSION, marker.name, popochiu_room.script_name]
            )
    
    # Save the scene if changes were made
    if changed and PopochiuEditorHelper.pack_scene(popochiu_room) != OK:
        PopochiuUtils.print_error(
            "Migration %d: Couldn't update [b]%s[/b] after updating markers." %
            [VERSION, popochiu_room.script_name]
        )

    return changed


#endregion