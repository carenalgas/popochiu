@icon('res://addons/popochiu/icons/room.png')
class_name PopochiuRoomData
extends Resource

@export var script_name := ''
@export_file("*.tscn") var scene := ''
@export var visited := false
@export var visited_first_time := false
@export var visited_times := 0

var props := {}
var hotspots := {}
var walkable_areas := {}
var regions := {}
var characters := {}


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
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


func save_characters() -> void:
	for c in E.current_room.get_characters():
		var pc: PopochiuCharacter = c

		characters[pc.script_name] = {
			x = pc.position.x,
			y = pc.position.y,
			facing = pc._looking_dir,
			# TODO: Store the state of the current animation (and more data if
			# necessary)
		}


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _save_object_state(node: Node2D, ignore: Array, target: Dictionary) -> void:
	var state := {}
	PopochiuResources.store_properties(state, node, ignore)
	
	# Add the PopochiuProp state to the room's props
	target[node.script_name] = state
