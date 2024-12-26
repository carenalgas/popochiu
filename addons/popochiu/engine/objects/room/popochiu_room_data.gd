@icon("res://addons/popochiu/icons/room.png")
class_name PopochiuRoomData
extends Resource
## This class is used to store information when saving and loading the game. It also ensures that
## the data remains throughout the game's execution.
##
## It also has data of the [PopochiuProp]s, [PopochiuHotspot]s, [PopochiuWalkableArea]s,
## [PopochiuRegion]s, and [PopochiuCharacter]s in a [PopochiuRoom].

## The identifier of the object used in scripts.
@export var script_name := ""
## The path to the scene file to be used when adding the character to the game during runtime.
@export_file("*.tscn") var scene := ""
## Whether the room was already visited by the player.
@export var visited := false
## Whether this is the first time the player visits the room.
@export var visited_first_time := false
## The number of times the player has visited this room.
@export var visited_times := 0

## Stores data about the [PopochiuProp]s in the room.
var props := {}
## Stores data about the [PopochiuHotspot]s in the room.
var hotspots := {}
## Stores data about the [PopochiuWalkableArea]s in the room.
var walkable_areas := {}
## Stores data about the [PopochiuRegion]s in the room.
var regions := {}
## Stores data about the [PopochiuCharacter]s in the room. To see the stored data by default, check
## [method save_characters].
var characters := {}


#region Virtual ####################################################################################
## Called when the game is saved.
## [i]Virtual[/i].
func _on_save() -> Dictionary:
	return {}


## Called when the game is loaded. The structure of [param data] is the same returned by
## [method _on_save].
## [i]Virtual[/i].
func _on_load(_data: Dictionary) -> void:
	pass


#endregion

#region Public #####################################################################################
## Use this to store custom data when saving the game. The returned [Dictionary] must contain only
## JSON supported types: [bool], [int], [float], [String].
func on_save() -> Dictionary:
	return _on_save()


## Called when the game is loaded. [param data] will have the same structure you defined for the
## returned [Dictionary] by [method _on_save].
func on_load(data: Dictionary) -> void:
	_on_load(data)


## Stores the data of each of the children inside [b]$WalkableAreas[/b], [b]$Props[/b],
## [b]$Hotspots[/b], [b]$Regions[/b], and [b]$Characters[/b].
func save_children_states() -> void:
	if PopochiuUtils.r.current and PopochiuUtils.r.current.state == self:
		for t in PopochiuResources.ROOM_CHILDREN:
			for node in PopochiuUtils.r.current.call("get_" + t):
				if node is PopochiuProp and not node.clickable: continue
				
				_save_object_state(
					node,
					PopochiuResources["%s_IGNORE" % (t as String).to_upper()],
					get(t)
				)
		
		# Save the state of characters
		save_characters()
		
		return
	
	var base_dir := resource_path.get_base_dir()
	var dependencies_paths: Array = Array(ResourceLoader.get_dependencies(
		resource_path.replace(".tres", ".tscn")
	)).map(
		func (dependency: String) -> String:
			return dependency.get_slice("::", 2)
	)
	
	for t in PopochiuResources.ROOM_CHILDREN:
		if (get(t) as Dictionary).is_empty():
			var category := (t as String).replace(" ", "")
			var objs_path := "%s/%s" % [base_dir, category]
			
			var dir := DirAccess.open(objs_path)
			
			if not dir: continue
			
			dir.include_hidden = false
			dir.include_navigational = false
			
			dir.list_dir_begin()
			
			var folder_name := dir.get_next()
			
			while folder_name != "":
				if dir.current_is_dir():
					# ---- Fix #320 ----------------------------------------------------------------
					# Ignore objects that are not part of the dependencies of the room. This is the
					# scenario where an object from the room was removed from the tree but not from
					# the file system
					var scene_path := "%s/%s/%s_%s.tscn" % [
						objs_path,
						folder_name,
						category.trim_suffix("s"),
						folder_name,
					]
					if not scene_path in dependencies_paths:
						folder_name = dir.get_next()
						continue
					# ---------------------------------------------------------------- Fix #320 ----
					
					var script_path := scene_path.replace("tscn", "gd")
					if not FileAccess.file_exists(script_path):
						folder_name = dir.get_next()
						continue
					
					var node: Node2D = load(script_path).new()
					node.script_name = folder_name.to_pascal_case()
					
					_save_object_state(
						node,
						PopochiuResources["%s_IGNORE" % (t as String).to_upper()],
						get(t)
					)
					
					node.free()
				
				folder_name = dir.get_next()


## Save room data related to the characters in the room. The stored data contains:
## [codeblock]{
##     x = PopochiuCharacter.position.x
##     y = PopochiuCharacter.position.y
##     facing = PopochiuCharacter._looking_dir
##     visible = PopochiuCharacter.visible
##     modulate = PopochiuCharacter.modulate
##     self_modulate = PopochiuCharacter.self_modulate
##     light_mask = PopochiuCharacter.light_mask
## }[/codeblock]
func save_characters() -> void:
	for character: PopochiuCharacter in PopochiuUtils.r.current.get_characters():
		characters[character.script_name] = {
			x = character.position.x,
			y = character.position.y,
			facing = character._looking_dir,
			visible = character.visible,
			modulate = character.modulate.to_html(),
			self_modulate = character.self_modulate.to_html(),
			light_mask = character.light_mask,
			baseline = character.baseline,
			# Store this values using built-in types
			walk_to_point = {
				x = character.walk_to_point.x,
				y = character.walk_to_point.y,
			},
			look_at_point = {
				x = character.look_at_point.x,
				y = character.look_at_point.y,
			},
			# TODO: Store the state of the current animation (and more data if
			# necessary)
		}


#endregion

#region Private ####################################################################################
func _save_object_state(node: Node2D, ignore: Array, target: Dictionary) -> void:
	var state := {}
	PopochiuResources.store_properties(state, node, ignore)
	
	# Add the PopochiuProp state to the room's props
	target[node.script_name] = state


#endregion
