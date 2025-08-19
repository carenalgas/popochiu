@tool
class_name PopochiuMigration8
extends PopochiuMigration

const VERSION = 8
const DESCRIPTION = "Add NavigationObstacle2D nodes to all props and update signal names"
const STEPS = [
	"Add ObstaclePolygon child nodes to existing props",
	"Update move_ended signal references to movement_ended in game scripts",
	"Add missing movement hook methods to all clickable scripts",
]


#region Virtual ####################################################################################
## This is code specific for this migration. This should return [code]true[/code] if the migration
## is successful. This is called from [method do_migration] which checks to make sure the migration
## should be done before calling this.
func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			_add_obstacle_polygons_to_props,
			_update_signal_references_in_game_scripts,
			_add_missing_movement_hooks
		]
	)


#endregion

#region Private ####################################################################################

## Add NavigationObstacle2D nodes to all props that don't already have one.
func _add_obstacle_polygons_to_props() -> Completion:
	var rooms_path := PopochiuResources.ROOMS_PATH
	PopochiuUtils.print_normal("Migration %d: Adding obstacle polygon to all props.")
	
	if not DirAccess.dir_exists_absolute(rooms_path):
		PopochiuUtils.print_error("Migration %d: Rooms directory does not exist: %s" % [VERSION, rooms_path])
		return Completion.IGNORED
	
	var any_prop_updated := false
	
	# Iterate through all rooms
	var rooms_dir := DirAccess.open(rooms_path)
	if rooms_dir == null:
		PopochiuUtils.print_error("Migration %d: Could not open rooms directory: %s" % [VERSION, rooms_path])
		return Completion.IGNORED
	
	rooms_dir.list_dir_begin()
	var room_name := rooms_dir.get_next()
	
	while room_name != "":
		if rooms_dir.current_is_dir():
			var props_path := rooms_path + room_name + "/props/"
			
			if DirAccess.dir_exists_absolute(props_path):
				# Process props in this room
				if _process_props_in_room(props_path):
					any_prop_updated = true
		room_name = rooms_dir.get_next()

	PopochiuUtils.print_normal("Migration %d: Obstacle polygon addition completed. %s props were updated" % [VERSION, "Some" if any_prop_updated else "No"])
	_reload_needed = any_prop_updated
	return Completion.DONE if any_prop_updated else Completion.IGNORED


## Process all props in a specific room's props folder.
func _process_props_in_room(props_path: String) -> bool:
	var any_prop_updated := false
	var props_dir := DirAccess.open(props_path)
	if props_dir == null:
		PopochiuUtils.print_error("Migration %d: Could not open props directory: %s" % [VERSION, props_path])
		return false
	
	props_dir.list_dir_begin()
	var prop_name := props_dir.get_next()
	
	while prop_name != "":
		if props_dir.current_is_dir():
			# Build the expected prop scene path directly
			var prop_scene_path := props_path + prop_name + "/" + "prop_" + prop_name + ".tscn"

			if FileAccess.file_exists(prop_scene_path):
				# Process one prop at a time to avoid memory issues
				if _update_prop_by_path(prop_scene_path):
					any_prop_updated = true
			else:
				PopochiuUtils.print_warning("Migration %d: Prop scene file does not exist: %s" % [VERSION, prop_scene_path])
		else:
			PopochiuUtils.print_warning("Migration %d: Skipping file (not directory): %s" % [VERSION, prop_name])
		prop_name = props_dir.get_next()
	
	return any_prop_updated


## Update a single prop by loading it from its scene path.
func _update_prop_by_path(scene_path: String) -> bool:
	var packed_scene: PackedScene = load(scene_path)
	if not packed_scene:
		PopochiuUtils.print_error("Migration %d: Could not load packed scene: %s" % [VERSION, scene_path])
		return false
	
	var prop_instance = packed_scene.instantiate()
	if not prop_instance is PopochiuProp:
		PopochiuUtils.print_error("Migration %d: Scene is not a PopochiuProp: %s" % [VERSION, scene_path])
		prop_instance.queue_free()
		return false
	
	# Check if the prop already has an ObstaclePolygon node
	if prop_instance.has_node("ObstaclePolygon"):
		PopochiuUtils.print_warning("Migration %d: Prop '%s' already has ObstaclePolygon, skipping" % [VERSION, prop_instance.script_name])
		prop_instance.queue_free()
		return false

	# Create and add the NavigationObstacle2D node
	var obstacle_polygon := NavigationObstacle2D.new()
	obstacle_polygon.name = "ObstaclePolygon"
	prop_instance.add_child(obstacle_polygon)
	obstacle_polygon.owner = prop_instance
	
	# Set default properties for the obstacle
	obstacle_polygon.affect_navigation_mesh = true

	# Save the scene
	if PopochiuEditorHelper.pack_scene(prop_instance) != OK:
		PopochiuUtils.print_error(
			"Migration %d: Couldn't update [b]%s[/b] after adding ObstaclePolygon." %
			[VERSION, prop_instance.script_name]
		)
		prop_instance.queue_free()
		return false

	PopochiuUtils.print_normal("Migration %d: Successfully updated prop '%s'" % [VERSION, prop_instance.script_name])

	# Clean up the instance
	prop_instance.queue_free()
	return true


## Update all game scripts to replace move_ended signal references with movement_ended.
func _update_signal_references_in_game_scripts() -> Completion:
	var game_path := PopochiuResources.GAME_PATH
	PopochiuUtils.print_normal("Migration %d: Updating reference to old signals." % [VERSION])
	
	if not DirAccess.dir_exists_absolute(game_path):
		PopochiuUtils.print_error("Migration %d: Game directory does not exist: %s" % [VERSION, game_path])
		return Completion.IGNORED
	
	var any_script_updated := false
	
	# Get all .gd files in the game folder recursively
	var script_files := PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(PopochiuResources.GAME_PATH, ["gd"])
	
	for script_path in script_files:
		if _update_signal_references_in_file(script_path):
			any_script_updated = true
	
	PopochiuUtils.print_normal("Migration %d: Signal references update completed. %s script updated: %s" % [VERSION, "Some" if any_script_updated else "No"])
	return Completion.DONE if any_script_updated else Completion.IGNORED


## Update signal references in a single script file.
func _update_signal_references_in_file(script_path: String) -> bool:
	# Read the file content
	var file := FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		PopochiuUtils.print_error(
			"Migration %d: Could not read file '%s'" % [VERSION, script_path]
		)
		return false
	
	var original_content := file.get_as_text()
	file.close()
	
	# Skip files that don't contain move_ended
	if not original_content.contains("move_ended"):
		PopochiuUtils.print_warning("Migration %d: Script '%s' does not contain 'move_ended', skipping" % [VERSION, script_path])
		return false
	
	# Create backup content for safety
	var backup_content := original_content
	
	# Patterns to replace (with word boundaries to avoid partial matches)
	var patterns_to_replace := [
		# Signal connections (with dot prefix)
		r"\.move_ended\.connect\(",
		# Signal connections (without dot prefix - local signals)
		r"\bmove_ended\.connect\(",
		# Signal disconnections (with dot prefix)
		r"\.move_ended\.disconnect\(",
		# Signal disconnections (without dot prefix)
		r"\bmove_ended\.disconnect\(",
		# Await statements (with object prefix)
		r"await\s+[a-zA-Z_][a-zA-Z0-9_]*\.move_ended\b",
		# Await statements (local signals)
		r"await\s+move_ended\b",
		# Signal emissions (with dot prefix)
		r"\.move_ended\.emit\(",
		# Signal emissions (without dot prefix)
		r"\bmove_ended\.emit\(",
		# Method names
		r"\b_on_move_ended\b",
	]
	
	var replacements := [
		".movement_ended.connect(",
		"movement_ended.connect(",
		".movement_ended.disconnect(",
		"movement_ended.disconnect(",
		func(match_result: RegExMatch) -> String:
			return match_result.get_string().replace("move_ended", "movement_ended"),
		"await movement_ended",
		".movement_ended.emit(",
		"movement_ended.emit(",
		"_on_movement_ended",
	]
	
	var updated_content := original_content
	var any_changes := false
	
	# Apply pattern replacements
	for i in range(patterns_to_replace.size()):
		var pattern: String = patterns_to_replace[i]
		var replacement = replacements[i]
		
		var regex := RegEx.new()
		var compile_result := regex.compile(pattern)
		if compile_result != OK:
			continue
		
		var matches := regex.search_all(updated_content)
		if matches.size() > 0:
			any_changes = true
			
			if replacement is Callable:
				# Handle special replacement functions
				for match in matches:
					var old_text := match.get_string()
					var new_text: String = replacement.call(match)
					updated_content = updated_content.replace(old_text, new_text)
			else:
				# Handle simple string replacements
				updated_content = regex.sub(updated_content, replacement, true)
	
	# If no changes were made, return false
	if not any_changes:
		PopochiuUtils.print_warning("Migration %d: No changes needed for script '%s'" % [VERSION, script_path])
		return false
	
	# Write the updated content back to the file
	file = FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		PopochiuUtils.print_error(
			"Migration %d: Could not write to file '%s'" % [VERSION, script_path]
		)
		return false
	
	file.store_string(updated_content)
	file.close()
	
	return true


## Add missing movement hook methods to all clickable scripts (characters, props, hotspots).
func _add_missing_movement_hooks() -> Completion:
	PopochiuUtils.print_normal("Migration %d: Adding movement hooks to scripts" % [VERSION])
	var any_script_updated := false
	
	# Process all types of clickable scripts
	var script_collections := [
		{
			"path": PopochiuResources.CHARACTERS_PATH,
			"type": "character",
			"get_scripts": _get_character_scripts
		},
		{
			"path": PopochiuResources.ROOMS_PATH,
			"type": "prop", 
			"get_scripts": _get_prop_scripts
		},
		{
			"path": PopochiuResources.ROOMS_PATH,
			"type": "hotspot",
			"get_scripts": _get_hotspot_scripts
		}
	]
	
	for collection in script_collections:
		var path: String = collection.path
		var type: String = collection.type
		var get_scripts_func: Callable = collection.get_scripts
		
		if not DirAccess.dir_exists_absolute(path):
			PopochiuUtils.print_warning("Migration %d: Path does not exist: %s" % [VERSION, path])
			continue
			
		var scripts := get_scripts_func.call(path)

		for script_path in scripts:
			if _add_missing_hooks_to_file(script_path, type):
				any_script_updated = true
	
	PopochiuUtils.print_normal("Migration %d: Movement hooks addition completed. %s scripts updated." % [VERSION, "Some" if any_script_updated else "No"])
	return Completion.DONE if any_script_updated else Completion.IGNORED


## Add missing movement hook methods to a single script file.
func _add_missing_hooks_to_file(script_path: String, clickable_type: String) -> bool:
	# Read the file content
	var file := FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		PopochiuUtils.print_error(
			"Migration %d: Could not read %s script '%s'" % [VERSION, clickable_type, script_path]
		)
		return false
	
	var original_content := file.get_as_text()
	file.close()
	
	# Check which methods are missing
	var has_movement_started := original_content.contains("_on_movement_started")
	var has_movement_ended := original_content.contains("_on_movement_ended")
	
	# If both methods exist, nothing to do
	if has_movement_started and has_movement_ended:
		PopochiuUtils.print_warning("Migration %d: Script already has both movement hooks, skipping" % [VERSION])
		return false
	
	var updated_content := original_content
	var methods_to_add := []
	
	# Prepare method templates based on what's missing
	if not has_movement_started:
		methods_to_add.append({
			"name": "_on_movement_started",
			"comment": "# Called when the %s starts moving" % clickable_type,
			"code": "func _on_movement_started() -> void:\n\tpass"
		})
	
	if not has_movement_ended:
		methods_to_add.append({
			"name": "_on_movement_ended", 
			"comment": "# Called when the %s stops moving" % clickable_type,
			"code": "func _on_movement_ended() -> void:\n\tpass"
		})
	
	# Find the best insertion point (before #endregion or at the end)
	var insertion_point := updated_content.rfind("#endregion\n\n#region Public")
	
	if insertion_point == -1:
		# If no #endregion found, add at the end
		insertion_point = updated_content.length()
		
	# Add the missing methods
	var methods_text := ""
	for method in methods_to_add:
		methods_text += "\n" + method.comment + "\n" + method.code
	
	# Insert the methods
	if insertion_point < updated_content.length():
		# Insert before #endregion
		updated_content = updated_content.substr(0, insertion_point) + methods_text + "\n\n" + updated_content.substr(insertion_point)
	else:
		# Append at end
		updated_content += methods_text + "\n"
	
	# Write the updated content back
	file = FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		PopochiuUtils.print_error(
			"Migration %d: Could not write to %s script '%s'" % [VERSION, clickable_type, script_path]
		)
		return false
	
	file.store_string(updated_content)
	file.close()
	
	return true


## Get all character script files.
func _get_character_scripts(characters_path: String) -> Array[String]:
	var character_scripts: Array[String] = []
	var dir := DirAccess.open(characters_path)
	if dir == null:
		PopochiuUtils.print_error("Migration %d: Could not open characters directory: %s" % [VERSION, characters_path])
		return character_scripts
	
	dir.list_dir_begin()
	var character_name := dir.get_next()
	
	while character_name != "":
		if dir.current_is_dir():
			var character_script_path := characters_path + character_name + "/" + "character_" + character_name + ".gd"
			if FileAccess.file_exists(character_script_path):
				character_scripts.append(character_script_path)
			else:
				PopochiuUtils.print_warning("Migration %d: Character script not found: %s" % [VERSION, character_script_path])
		
		character_name = dir.get_next()
	
	return character_scripts
    

## Get all prop script files from all rooms.
func _get_prop_scripts(base_path: String) -> Array[String]:
	return _get_room_scripts(base_path, "props", "prop")


## Get all hotspot script files from all rooms.
func _get_hotspot_scripts(base_path: String) -> Array[String]:
	return _get_room_scripts(base_path, "hotspots", "hotspot")


## Get all scripts of a specific type from room subfolders.
func _get_room_scripts(base_path: String, subfolder: String, script_prefix: String) -> Array[String]:
	var scripts: Array[String] = []
	var rooms_dir := DirAccess.open(base_path)
	if rooms_dir == null:
		PopochiuUtils.print_error("Migration %d: Could not open rooms directory: %s" % [VERSION, base_path])
		return scripts
	
	rooms_dir.list_dir_begin()
	var room_name := rooms_dir.get_next()
	
	while room_name != "":
		if rooms_dir.current_is_dir():
			var folder_path := base_path + room_name + "/" + subfolder + "/"
			if DirAccess.dir_exists_absolute(folder_path):
				var folder_dir := DirAccess.open(folder_path)
				if folder_dir != null:
					folder_dir.list_dir_begin()
					var item_name := folder_dir.get_next()
					
					while item_name != "":
						if folder_dir.current_is_dir():
							var script_path := folder_path + item_name + "/" + script_prefix + "_" + item_name + ".gd"
							if FileAccess.file_exists(script_path):
								scripts.append(script_path)
							else:
								PopochiuUtils.print_warning("Migration %d: %s script not found: %s" % [VERSION, script_prefix.capitalize(), script_path])
						item_name = folder_dir.get_next()
		room_name = rooms_dir.get_next()
	
	return scripts


#endregion
