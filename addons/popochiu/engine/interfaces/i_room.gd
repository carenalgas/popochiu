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
## R.Outside.state.is_rainning # Access the is_rainning property in the Outside room
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
## This method is used by [b]res://game/autoloads/r.gd[/b] to load the instace of each room (present
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
	var tres_path: String = PopochiuResources.get_data_value("rooms", script_name, "")
	
	if not tres_path:
		PopochiuUtils.print_error("Room [b]%s[/b] doesn't exist in the project" % script_name)
		return null
	
	return load(load(tres_path).scene).instantiate()


## Clears all the [PopochiuRoom] instances to free memory and orphan childs.
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
	if not E.in_room: return
	
	E.in_room = false
	G.block()
	
	_use_transition_on_room_change = use_transition
	if use_transition:
		E.tl.play_transition(E.tl.FADE_IN)
		await E.tl.transition_finished
	
	# Prevent the GUI from showing info coming from the previous room
	G.show_hover_text()
	Cursor.show_cursor()
	
	if is_instance_valid(C.player) and Engine.get_process_frames() > 0:
		C.player.last_room = current.script_name
	
	# Store the room state
	if store_state:
		rooms_states[current.script_name] = current.state
		current.state.save_children_states()
	
	# Remove PopochiuCharacter nodes from the room so they are not deleted
	if Engine.get_process_frames() > 0:
		current.exit_room()
	
	# Reset camera config
	E.camera.restore_default_limits()
	
	if ignore_change:
		return
	
	var rp: String = PopochiuResources.get_data_value("rooms", script_name, null)
	if rp.is_empty():
		PopochiuUtils.print_error(
			"Can't go to room [b]%s[/b] because it doesn't exist" % script_name
		)
		return
	
	if Engine.get_process_frames() == 0:
		await get_tree().process_frame
	
	clear_instances()
	
	E.clear_hovered()
	E.get_tree().change_scene_to_file(load(rp).scene)


## Called once the loaded [param room] is "ready" ([method Node._ready]).
func room_readied(room: PopochiuRoom) -> void:
	if not is_instance_valid(current):
		current = room
	
	# When running from the Editor the first time, use goto_room
	if Engine.get_process_frames() == 0:
		await get_tree().process_frame
		E.in_room = true
		
		# Calling this will make the camera be set to its default values and will store the state of
		# the main room (the last parameter will prevent Popochiu from changing the scene to the
		# same that is already loaded)
		# TODO: We should have an option in Popochiu Settings which allows devs to turn on the scene
		# transition effect even when they are opened from the Editor (by pressing F5, F6 or using
		# the buttons to play a scene. This option will be linked to the second parameter of the
		# goto_room function, and we'll have to make sure the transition layer starts visible in
		# those cases (as if it were coming from another room).
		await goto_room(room.script_name, false, true, true)
	
	# Make the camera be ready for the room
	current.setup_camera()
	
	# Update the core state
	if E.loaded_game:
		C.player = C.get_character(E.loaded_game.player.id)
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
		var chr: PopochiuCharacter = C.get_character(chr_script_name)
		
		if not chr: continue
		
		chr.position = Vector2(chr_dic.x, chr_dic.y)
		chr._looking_dir = chr_dic.facing
		chr.visible = chr_dic.visible
		chr.modulate = Color.from_string(chr_dic.modulate, Color.WHITE)
		chr.self_modulate = Color.from_string(chr_dic.self_modulate, Color.WHITE)
		chr.light_mask = chr_dic.light_mask
		chr.baseline = chr_dic.baseline
		chr.walk_to_point = chr_dic.walk_to_point
		
		current.add_character(chr)
	
	# If the room must have the player character but it is not part of its $Characters node, then
	# add the PopochiuCharacter to the room
	if (
		current.has_player
		and is_instance_valid(C.player)
		and not current.has_character(C.player.script_name)
	):
		current.add_character(C.player)
		# Place the PC in the middle of the room
		C.player.position = Vector2(E.width, E.height) / 2.0
		await C.player.idle()
	
	# Load the state of Props, Hotspots, Regions and WalkableAreas
	for type in PopochiuResources.ROOM_CHILDREN:
		for script_name in rooms_states[room.script_name][type]:
			var node: Node2D = current.callv(
				"get_" + type.trim_suffix("s"),
				[(script_name as String).to_pascal_case()]
			)
			var node_dic: Dictionary =\
			rooms_states[room.script_name][type][script_name]
			
			for property in node_dic:
				if not PopochiuResources.has_property(node, property): continue
				
				node[property] = node_dic[property]
	
	for c in get_tree().get_nodes_in_group("PopochiuClickable"):
		c.room = current
	
	await current._on_room_entered()
	
	if E.loaded_game:
		C.player.global_position = Vector2(
			E.loaded_game.player.position.x,
			E.loaded_game.player.position.y
		)
	
	if _use_transition_on_room_change:
		E.tl.play_transition(E.tl.FADE_OUT)
		await E.tl.transition_finished
		
		await E.wait(0.3)
	else:
		await get_tree().process_frame
	
	if not current.hide_gui:
		G.unblock()
	
	if E.hovered:
		G.mouse_entered_clickable.emit(E.hovered)
	
	E.in_room = true
	
	if E.loaded_game:
		E.game_loaded.emit(E.loaded_game)
		await G.load_feedback_finished
		
		E.loaded_game = {}
	
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
