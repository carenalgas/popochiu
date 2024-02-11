@icon('res://addons/popochiu/icons/room.png')
class_name PopochiuRoomData
extends Resource
## This class is used to store information when saving and loading the game. It also ensures that
## the data remains throughout the game's execution.
##
## It also has data of the [PopochiuProp]s, [PopochiuHotspot]s, [PopochiuWalkableArea]s,
## [PopochiuRegion]s, and [PopochiuCharacter]s in a [PopochiuRoom].

## The identifier of the object used in scripts.
@export var script_name := ''
## The path to the scene file to be used when adding the character to the game during runtime.
@export_file("*.tscn") var scene := ''
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


## Stores the data of each of the childrens inside [b]$WalkableAreas[/b], [b]$Props[/b],
## [b]$Hotspots[/b], [b]$Regions[/b], and [b]$Characters[/b].
func save_childs_states() -> void:
	if E.current_room and E.current_room.state == self:
		for t in PopochiuResources.ROOM_CHILDS:
			for node in E.current_room.call('get_' + t):
				if node is PopochiuProp and not node.clickable: continue
				
				_save_object_state(
					node,
					PopochiuResources['%s_IGNORE' % (t as String).to_upper()],
					get(t)
				)
		
		# Save the state of characters
		save_characters()
		
		return
	
	var base_dir := resource_path.get_base_dir()
	
	for t in PopochiuResources.ROOM_CHILDS:
		if (get(t) as Dictionary).is_empty():
			var category := (t as String).replace(' ', '')
			var objs_path := '%s/%s' % [base_dir, category]
			
			var dir := DirAccess.open(objs_path)
			
			if not dir: continue
			
			dir.include_hidden = false
			dir.include_navigational = false
			
			dir.list_dir_begin()
			
			var folder_name := dir.get_next()
			
			while folder_name != '':
				if dir.current_is_dir():
					
					var script_path := '%s/%s/%s_%s.gd' % [
						objs_path,
						folder_name,
						category.trim_suffix('s'),
						folder_name,
					]
					
					if not FileAccess.file_exists(script_path):
						folder_name = dir.get_next()
						continue
					
					var node: Node2D = load(script_path).new()
					node.script_name = folder_name
					
					_save_object_state(
						node,
						PopochiuResources['%s_IGNORE' % (t as String).to_upper()],
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
	for c in E.current_room.get_characters():
		var pc: PopochiuCharacter = c

		characters[pc.script_name] = {
			x = pc.position.x,
			y = pc.position.y,
			facing = pc._looking_dir,
			visible = pc.visible,
			modulate = pc.modulate,
			self_modulate = pc.self_modulate,
			light_mask = pc.light_mask
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
