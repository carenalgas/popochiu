extends EditorInspectorPlugin


#region Virtual ####################################################################################
func _can_handle(object: Object) -> bool:
	if object is PopochiuProp:
		return true
	return false


func _parse_property(
	object: Object,
	type,
	path: String,
	hint,
	hint_text: String,
	usage,
	wide: bool
) -> bool:
	if (
		object.get_class() == "EditorDebuggerRemoteObject"
		or object is not PopochiuProp
		or path != "link_to_item"
	):
		return false
	
	var ep := EditorProperty.new()
	var ob := OptionButton.new()
	
	_update_items_list(ob, object)
	
	ob.item_selected.connect(_update_link_to_item.bind(ob, object))
	ob.pressed.connect(_update_items_list.bind(ob, object))
	
	ep.add_child(ob)
	add_property_editor(path, ep)
	
	return true


#endregion

#region Private ####################################################################################
func _update_items_list(ob: OptionButton, prop: PopochiuProp) -> void:
	ob.clear()
	var inventory_items := PopochiuResources.get_section_keys("inventory_items")
	var keys_ids_map := {}
	
	inventory_items.sort()
	ob.add_item("")
	for key: String in inventory_items:
		keys_ids_map[key] = ob.item_count
		ob.add_item(key)
	
	if keys_ids_map.has(prop.link_to_item):
		ob.selected = ob.get_item_index(keys_ids_map[prop.link_to_item])


func _update_link_to_item(idx: int, ob: OptionButton, prop: PopochiuProp) -> void:
	prop.link_to_item = ob.get_item_text(idx)


#endregion
