extends EditorExportPlugin

const LOCAL_OBJ_CONFIG = preload("res://addons/popochiu/editor/config/local_obj_config.gd")

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	var file := FileAccess.open(PopochiuResources.DATA, FileAccess.READ)
	if file:
		add_file(PopochiuResources.DATA, file.get_buffer(file.get_length()), false)
	
	file.close()

# Logic for Aseprite Importer
# This code removes importer's metadata from nodes before exporting them
# Thanks to Vinicius Gerevini and his Aseprite Wizard plugin for that!
# This code is run independent of the importer to be enabled, to clean things up.
# TODO: may be moved to another file so we keep things separated
func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	if type != "PackedScene": return

	var scene : PackedScene =  ResourceLoader.load(path, type, 0)
	var scene_changed := false
	var root_node: Node = scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	var nodes := [root_node]

	#remove metadata from scene
	while not nodes.is_empty():
		var node : Node = nodes.pop_front()

		for child in node.get_children():
			nodes.push_back(child)

		if _remove_meta(node, path):
			scene_changed = true

	#save scene if changed
	if scene_changed:
		var filtered_scene := PackedScene.new()
		if filtered_scene.pack(root_node) != OK:
			PopochiuUtils.print_error("Error updating scene.")
			return

		var content := _get_scene_content(path, filtered_scene)

		add_file(path, content, true)

	root_node.free()


func _remove_meta(node:Node, path: String) -> bool:
	if node.has_meta(LOCAL_OBJ_CONFIG.LOCAL_OBJ_CONFIG_META_NAME):
		node.remove_meta(LOCAL_OBJ_CONFIG.LOCAL_OBJ_CONFIG_META_NAME)
		PopochiuUtils.print_normal("Aseprite Importer: Removed metadata from scene %s" % path)
		
		return true

	return false


func _get_scene_content(path:String, scene:PackedScene) -> PackedByteArray:
	var tmp_path = OS.get_cache_dir()  + "tmp_scene." + path.get_extension()
	ResourceSaver.save(scene, tmp_path)

	var tmp_file = FileAccess.open(tmp_path, FileAccess.READ)
	var content : PackedByteArray = tmp_file.get_buffer(tmp_file.get_length())

	var tmp_dir := DirAccess.open(tmp_path)
	if tmp_dir and tmp_dir.file_exists(tmp_path):
		tmp_dir.remove(tmp_path)

	return content
