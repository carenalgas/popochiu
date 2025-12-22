class_name PopochiuIRoom
extends Node
## Provides access to the [PopochiuRoom]s in the game. Access with [b]R[/b] (e.g.
## [code]R.House.get_prop("Drawer")[/code]).
##
## Use it to access props, hotspots, regions and walkable areas in the current room; or to access to
## data from other rooms. Its script is [b]i_room.gd[/b].[br][br]
##
## Some things you can do with it:[br][br]
## [b]•[/b] Access objects inside the current room.[br]
## [b]•[/b] Access the state of any room.[br]
## [b]•[/b] Move to another room.[br][br]
##
## Examples:
## [codeblock]
## R.get_prop("Scissors").modulate.a = 1.0 # Get Scissors prop and make it visible
## R.Outside.state.is_raining # Access the is_raining property in the Outside room
## [/codeblock]

## Provides access to the current [PopochiuRoom].
var current: PopochiuRoom = null : set = set_current
## Stores the state of each [PopochiuRoom] in the game. The key of each room is its
## [member PopochiuRoom.script_name], and each value is a [Dictionary] with its properties and the
## data of all its [PopochiuProp]s, [PopochiuHotspot]s, [PopochiuWalkableArea]s, [PopochiuRegion]s,
## and some data related with the [PopochiuCharacter]s in it. For more info about the data stored,
## check the documentation for [PopochiuRoomData].
var rooms_states := {}

var _room_instances := {}
var _use_transition_on_room_change := true
# Stores characters that should be transferred to the target room when following across rooms.
# Each entry is a dictionary: { character: PopochiuCharacter, followed_script_name: String, offset: Vector2 }
var _pending_cross_room_followers := []


#region Godot ######################################################################################
func _init() -> void:
	Engine.register_singleton(&"R", self)


#endregion

#region Public #####################################################################################
## Retrieves the [PopochiuProp] with a [member PopochiuClickable.script_name] matching
## [param prop_name].
func get_prop(prop_name: String) -> PopochiuProp:
	return current.get_prop(prop_name)


## Retrieves the [PopochiuHotspot] with a [member PopochiuClickable.script_name] matching
## [param hotspot_name].
func get_hotspot(hotspot_name: String) -> PopochiuHotspot:
	return current.get_hotspot(hotspot_name)


## Retrieves the [PopochiuRegion] with a [member PopochiuRegion.script_name] matching
## [param region_name].
func get_region(region_name: String) -> PopochiuRegion:
	return current.get_region(region_name)


## Retrieves the [PopochiuWalkableArea] with a [member PopochiuWalkableArea.script_name] matching
## [param walkable_area_name].
func get_walkable_area(walkable_area_name: String) -> PopochiuWalkableArea:
	return current.get_walkable_area(walkable_area_name)


## Retrieves the [Marker2D] with a [member Node.name] matching [param marker_name].
func get_marker(marker_name: String) -> Marker2D:
	return current.get_marker(marker_name)


## Retrieves the [b]global position[/b] of the [Marker2D] with a [member Node.name] matching
## [param marker_name].
func get_marker_position(marker_name: String) -> Vector2:
	return current.get_marker_position(marker_name)


## Returns all the [PopochiuProp]s in the room.
func get_props() -> Array:
	return get_tree().get_nodes_in_group("props")


## Returns all the [PopochiuHotspot]s in the room.
func get_hotspots() -> Array:
	return get_tree().get_nodes_in_group("hotspots")


## Returns all the [PopochiuRegion]s in the room.
func get_regions() -> Array:
	return get_tree().get_nodes_in_group("regions")


## Returns all the [PopochiuWalkableArea]s in the room.
func get_walkable_areas() -> Array:
	return get_tree().get_nodes_in_group("walkable_areas")


## Returns all the [Marker2D]s in the room.
func get_markers() -> Array:
	return current.get_markers()


## Returns the instance of the [PopochiuRoom] identified with [param script_name]. If the room
## doesn't exists, then [code]null[/code] is returned.[br][br]
## This method is used by [b]res://game/autoloads/r.gd[/b] to load the instance of each room (present
## in that script as a variable for code autocompletion) in runtime.
func get_runtime_room(script_name: String) -> PopochiuRoom:
	var room: PopochiuRoom = null
	
	if _room_instances.has(script_name):
		room = _room_instances[script_name]
	else:
		room = get_instance(script_name)
	
		if room:
			_room_instances[room.script_name] = room
	
	return room


## Gets the instance of the [PopochiuRoom] identified with [param script_name].
func get_instance(script_name: String) -> PopochiuRoom:
	# Fix #328 by returning the instance of the current room if it matches the instance that the
	# plugin is looking for
	if is_instance_valid(current) and current.script_name == script_name:
		return current
	
	var tres_path: String = PopochiuResources.get_data_value("rooms", script_name, "")
	
	if not tres_path:
		PopochiuUtils.print_error("Room [b]%s[/b] doesn't exist in the project" % script_name)
		return null
	
	return load(load(tres_path).scene).instantiate()


## Clears all the [PopochiuRoom] instances to free memory and orphan children.
func clear_instances() -> void:
	for r in _room_instances:
		(_room_instances[r] as PopochiuRoom).free()
	
	_room_instances.clear()


## Loads the room with [param script_name]. [param use_transition] can be used to trigger a [i]fade
## out[/i] animation before loading the room, and a [i]fade in[/i] animation once it is ready.
## If [param store_state] is [code]true[/code] the state of the room will be stored in memory.
## [param ignore_change] is used internally by Popochiu to know if it's the first time the room is
## loaded when starting the game.
func goto_room(
	script_name := "",
	use_transition := true,
	store_state := true,
	ignore_change := false
) -> void:
	if not PopochiuUtils.e.in_room: return
	
	PopochiuUtils.e.in_room = false
	PopochiuUtils.g.block()
	
	_use_transition_on_room_change = use_transition
	# Never fade the TL in, if we are entering the first room at game start
	if use_transition and Engine.get_process_frames() > 0:
		PopochiuUtils.e.tl.play_transition(PopochiuUtils.e.tl.FADE_IN)
		await PopochiuUtils.e.tl.transition_finished
	elif Engine.get_process_frames() > 0:
		PopochiuUtils.e.tl.show_curtain()
	
	# Prevent the GUI from showing info coming from the previous room
	PopochiuUtils.g.show_hover_text()
	PopochiuUtils.cursor.show_cursor()
	
	if is_instance_valid(PopochiuUtils.c.player) and Engine.get_process_frames() > 0:
		PopochiuUtils.c.player.last_room = current.script_name
	
	# Collect characters that should follow across rooms before saving state.
	# This must happen before save_children_states() so followers are excluded from source room.
	if Engine.get_process_frames() > 0:
		_collect_cross_room_followers()
	
	# Store the room state
	if store_state:
		rooms_states[current.script_name] = current.state
		current.state.save_children_states()
	
	# Remove PopochiuCharacter nodes from the room so they are not deleted
	if Engine.get_process_frames() > 0:
		current.exit_room()
	
	# Reset camera config
	PopochiuUtils.e.camera.restore_default_limits()
	
	if ignore_change:
		return
	
	var rp: String = PopochiuResources.get_data_value("rooms", script_name, "")
	if rp.is_empty():
		PopochiuUtils.print_error(
			"Can't go to room [b]%s[/b] because it doesn't exist" % script_name
		)
		return
	
	if Engine.get_process_frames() == 0:
		await get_tree().process_frame
	
	clear_instances()
	
	PopochiuUtils.e.clear_hovered()
	PopochiuUtils.e.get_tree().change_scene_to_file(load(rp).scene)


## Called once the loaded [param room] is "ready" ([method Node._ready]).
func room_readied(room: PopochiuRoom) -> void:
	if not is_instance_valid(current):
		current = room
	
	# When running from the Editor the first time, use goto_room
	if Engine.get_process_frames() == 0:
		await get_tree().process_frame
		PopochiuUtils.e.in_room = true

		# Calling this will make the camera be set to its default values and will store the state of
		# the main room (the last parameter will prevent Popochiu from changing the scene to the
		# same that is already loaded).
		# Also, use the transition layer to fade in the room, if the setting is enabled.
		await goto_room(room.script_name, PopochiuUtils.e.settings.show_tl_in_first_room, true, true)
	
	# Make the camera be ready for the room
	current.setup_camera()
	
	# Update the core state
	if PopochiuUtils.e.loaded_game:
		PopochiuUtils.c.player = PopochiuUtils.c.get_character(PopochiuUtils.e.loaded_game.player.id)
	else:
		current.state.visited = true
		current.state.visited_times += 1
		current.state.visited_first_time = current.state.visited_times == 1
	
	# Add the PopochiuCharacter instances to the room
	if (rooms_states[room.script_name]["characters"] as Dictionary).is_empty():
		# Store the initial state of the characters in the room
		current.state.save_characters()
	
	current.clean_characters()
	
	# Load the state of characters in the room
	for chr_script_name: String in rooms_states[room.script_name]["characters"]:
		var chr_dic: Dictionary = rooms_states[room.script_name]["characters"][chr_script_name]
		var chr: PopochiuCharacter = PopochiuUtils.c.get_character(chr_script_name)
		
		if not chr: continue
		
		# If character is already in another room's tree, remove it first
		# This can happen when the same character instance is saved in multiple rooms
		if chr.is_inside_tree():
			var parent := chr.get_parent()
			if parent:
				parent.remove_child(chr)

		chr.position = Vector2(chr_dic.x, chr_dic.y)
		chr._looking_dir = chr_dic.facing
		chr.visible = chr_dic.visible
		chr.modulate = Color.from_string(chr_dic.modulate, Color.WHITE)
		chr.self_modulate = Color.from_string(chr_dic.self_modulate, Color.WHITE)
		chr.light_mask = chr_dic.light_mask
		chr.baseline = chr_dic.baseline
		
		if chr_dic.has("walk_to_point"):
			chr.walk_to_point = PopochiuUtils.unpack_vector_2(chr_dic.walk_to_point)
		
		if chr_dic.has("look_at_point"):
			chr.look_at_point = PopochiuUtils.unpack_vector_2(chr_dic.look_at_point)

		if chr_dic.has("dialog_pos"):
			chr.dialog_pos = PopochiuUtils.unpack_vector_2(chr_dic.dialog_pos)

		# Restore follow-related properties
		if chr_dic.has("follow_character_outside_room"):
			chr.follow_character_outside_room = chr_dic.follow_character_outside_room
		
		if chr_dic.has("follow_character_offset"):
			chr.follow_character_offset = PopochiuUtils.unpack_vector_2(chr_dic.follow_character_offset)
		
		if chr_dic.has("follow_character_threshold"):
			chr.follow_character_threshold = PopochiuUtils.unpack_vector_2(chr_dic.follow_character_threshold)
		
		# Restore face_character link after character is added to the room
		if chr_dic.has("face_character") and chr_dic.face_character:
			chr.face_character = chr_dic.face_character
		
		# Restore follow link after character is added to the room
		# This must happen after add_character() so the character is in the tree
		if chr_dic.has("follow_character") and chr_dic.follow_character:
			chr.follow_character = chr_dic.follow_character

		current.add_character(chr)

		# Restore face link after character is added to the room
		if not chr.face_character.is_empty():
			var faced_chr := PopochiuUtils.c.get_character(chr.face_character)
			if is_instance_valid(faced_chr) and faced_chr.is_inside_tree():
				chr.start_facing_character(faced_chr)

		# Restore follow link after character is added to the room
		if not chr.follow_character.is_empty():
			var followed_chr := PopochiuUtils.c.get_character(chr.follow_character)
			if is_instance_valid(followed_chr) and followed_chr.is_inside_tree():
				chr.start_following_character(followed_chr)

	# If the room must have the player character but it is not part of its $Characters node, then
	# add the PopochiuCharacter to the room
	if (
		current.has_player
		and is_instance_valid(PopochiuUtils.c.player)
		and not current.has_character(PopochiuUtils.c.player.script_name)
	):
		current.add_character(PopochiuUtils.c.player)
		# Place the PC in the middle of the room
		PopochiuUtils.c.player.position = Vector2(PopochiuUtils.e.width, PopochiuUtils.e.height) / 2.0
		await PopochiuUtils.c.player.idle()
	
	# Load the state of Props, Hotspots, Regions and WalkableAreas
	for type in PopochiuResources.ROOM_CHILDREN:
		for script_name in rooms_states[room.script_name][type]:
			var node: Node2D = current.callv(
				"get_" + type.trim_suffix("s"),
				[(script_name as String).to_pascal_case()]
			)
			
			if not is_instance_valid(node):
				# Fix #320 by ignoring the object if it doesn't exist inside the Room
				continue
			
			var node_dic: Dictionary =\
			rooms_states[room.script_name][type][script_name]
			
			for property in node_dic:
				if not PopochiuResources.has_property(node, property): continue
				
				node[property] = node_dic[property]
	
	for c in get_tree().get_nodes_in_group("PopochiuClickable"):
		c.room = current
	
	await current._on_room_entered()
	
	# Add characters that followed across rooms AFTER _on_room_entered() so the followed
	# character (e.g., player) is already at their final position set by the room script.
	_add_cross_room_followers()
	
	if PopochiuUtils.e.loaded_game:
		PopochiuUtils.c.player.global_position = Vector2(
			PopochiuUtils.e.loaded_game.player.position.x,
			PopochiuUtils.e.loaded_game.player.position.y
		)
	
	if _use_transition_on_room_change:
		PopochiuUtils.e.tl.play_transition(PopochiuUtils.e.tl.FADE_OUT)
		await PopochiuUtils.e.tl.transition_finished
		
		await PopochiuUtils.e.wait(0.3)
	else:
		PopochiuUtils.e.tl.hide_curtain()
		await get_tree().process_frame
	
	if not current.hide_gui:
		PopochiuUtils.g.unblock()
	
	if PopochiuUtils.e.hovered:
		PopochiuUtils.g.mouse_entered_clickable.emit(PopochiuUtils.e.hovered)
	
	PopochiuUtils.e.in_room = true
	
	if PopochiuUtils.e.loaded_game:
		PopochiuUtils.e.game_loaded.emit(PopochiuUtils.e.loaded_game)
		await PopochiuUtils.g.load_feedback_finished
		
		PopochiuUtils.e.loaded_game = {}
	
	# This enables the room to listen input events
	current.is_current = true
	await current._on_room_transition_finished()
	
	# Fix #219: Update visited_first_time state once _on_room_transition_finished() finishes
	current.state.visited_first_time = false


func store_states() -> void:
	# Store the default state of rooms in the game
	for room_tres in PopochiuResources.get_section("rooms"):
		var res: PopochiuRoomData = load(room_tres)
		rooms_states[res.script_name] = res
		res.save_children_states()


#endregion

#region SetGet #####################################################################################
func set_current(value: PopochiuRoom) -> void:
	if not value.is_inside_tree():
		goto_room(value.script_name)
	else:
		current = value


#endregion


#region Private ####################################################################################
# Collects characters that should follow across rooms.
# Iterates through characters in the current room and identifies those with follow_character_outside_room
# enabled and a valid _current_followed_character. Builds chain recursively and orders result
# so followed characters come before their followers.
func _collect_cross_room_followers() -> void:
	_pending_cross_room_followers.clear()
	
	if not is_instance_valid(current):
		return
	
	# Get all characters currently in the room
	var characters_in_room := current.get_characters()
	if characters_in_room.is_empty():
		return
	
	# Build a map of who follows whom for chain detection
	var follower_map := {}  # followed_script_name -> Array of followers
	for chr: PopochiuCharacter in characters_in_room:
		if (
			chr.follow_character_outside_room
			and is_instance_valid(chr._current_followed_character)
			and chr != PopochiuUtils.c.player  # Player character doesn't auto-follow
		):
			var followed_name: String = chr._current_followed_character.script_name
			if not follower_map.has(followed_name):
				follower_map[followed_name] = []
			follower_map[followed_name].append(chr)
	
	if follower_map.is_empty():
		return
	
	# Find the root of the follow chain (the character being followed who isn't following anyone
	# with follow_character_outside_room, or is the player)
	var roots: Array[String] = []
	for followed_name: String in follower_map:
		var followed_chr: PopochiuCharacter = PopochiuUtils.c.get_character(followed_name)
		if not is_instance_valid(followed_chr):
			continue
		# A root is a character who is followed but either:
		# - Is the player
		# - Doesn't have follow_character_outside_room enabled
		# - Isn't following anyone in the room
		var is_root: bool = (
			followed_chr == PopochiuUtils.c.player
			or not followed_chr.follow_character_outside_room
			or not is_instance_valid(followed_chr._current_followed_character)
		)
		if is_root:
			roots.append(followed_name)
	
	# Process chains starting from roots, adding followers in order (followed first, then followers)
	var processed := {}
	for root_name in roots:
		_collect_followers_recursive(root_name, follower_map, processed)
	
	# Remove collected followers from the current room so they won't be saved in source room state
	for entry in _pending_cross_room_followers:
		var follower: PopochiuCharacter = entry.character
		if current.has_character(follower.script_name):
			current.remove_character(follower)


# Recursively collects followers in the correct order (followed characters before their followers).
func _collect_followers_recursive(
	followed_name: String,
	follower_map: Dictionary,
	processed: Dictionary
) -> void:
	if not follower_map.has(followed_name):
		return
	
	for follower: PopochiuCharacter in follower_map[followed_name]:
		if processed.has(follower.script_name):
			continue
		
		processed[follower.script_name] = true
		
		# Store the follower info
		_pending_cross_room_followers.append({
			"character": follower,
			"followed_script_name": followed_name,
			"offset": follower.follow_character_offset
		})
		
		# Recursively process anyone following this follower
		_collect_followers_recursive(follower.script_name, follower_map, processed)


# Adds characters that followed across rooms to the current room.
# Positions them relative to their followed character and re-establishes the follow link.
func _add_cross_room_followers() -> void:
	if _pending_cross_room_followers.is_empty():
		return
	
	for entry: Dictionary in _pending_cross_room_followers:
		var follower: PopochiuCharacter = entry.character
		var followed_name: String = entry.followed_script_name
		var offset: Vector2 = entry.offset
		
		# Get the followed character (should already be in the room)
		var followed := PopochiuUtils.c.get_character(followed_name)
		if not is_instance_valid(followed):
			PopochiuUtils.print_warning(
				"Cross-room follower '%s' could not find followed character '%s'" %
				[follower.script_name, followed_name]
			)
			continue
		
		# Add the follower to the room first
		if not current.has_character(follower.script_name):
			current.add_character(follower)
		
		# Stop any ongoing movement before repositioning
		follower.stop_walking()
		
		# Position the follower relative to the followed character AFTER add_character(),
		# because add_character() calls update_position() which would overwrite with the
		# stale _buffered_position from the previous room.
		var target_position: Vector2 = followed.position + offset
		follower.position = target_position
		# Sync the buffered position so it doesn't jump back when movement starts
		follower.sync_buffered_position()
		
		# Re-establish the follow link
		follower.start_following_character(followed)
	
	_pending_cross_room_followers.clear()


#endregion
