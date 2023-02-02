class_name PopochiuRoomData, 'res://addons/Popochiu/icons/room.png'
extends Resource

export var script_name := ''
export(String, FILE, "*.tscn") var scene = ''

export var visited := false
export var visited_first_time := false
export var visited_times := 0

var props := {}
var hotspots := {}
var walkable_areas := {}
var regions := {}


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
		
		return
	
	var base_dir := resource_path.get_base_dir()
	var dir := Directory.new()
	
	for t in PopochiuResources.ROOM_CHILDS:
		if not get(t):
			var category := (t as String).capitalize().replace(' ', '')
			var objs_path := '%s/%s' % [base_dir, category]
			
			if dir.open(objs_path) != OK: continue
			
			dir.list_dir_begin(true)
			
			var folder_name := dir.get_next()
			
			while folder_name != '':
				if dir.current_is_dir() and folder_name != '_NoInteraction':
					var script_path := '%s/%s/%s%s.gd' % [
						objs_path,
						folder_name,
						category.trim_suffix('s'),
						folder_name,
					]
					
					var node: Node2D = load(script_path).new()
					node.script_name = folder_name
					
					_save_object_state(
						node,
						PopochiuResources['%s_IGNORE' % (t as String).to_upper()],
						get(t)
					)
					
					node.free()
				
				folder_name = dir.get_next()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _save_object_state(node: Node2D, ignore: Array, target: Dictionary) -> void:
	var state := {}
	PopochiuResources.store_properties(state, node, ignore)
	
	# Add the PopochiuProp state to the room's props
	target[node.script_name] = state
