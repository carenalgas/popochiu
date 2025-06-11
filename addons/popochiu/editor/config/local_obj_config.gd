@tool
extends RefCounted


const LOCAL_OBJ_CONFIG_META_NAME = "_popochiu_aseprite_config_"
const LOCAL_OBJ_CONFIG_MARKER = "popochiu_aseprite_config"
const SEPARATOR = "|="



#region Public ####################################################################################
static func encode(object: Dictionary):
	var text = "%s\n" % LOCAL_OBJ_CONFIG_MARKER

	for prop in object:
		text += "%s%s%s\n" % [prop, SEPARATOR, object[prop]]

	return Marshalls.utf8_to_base64(text)


static func decode(string: String):
	var decoded = _decode_base64(string)
	if not _is_valid_config(decoded):
		return null
	
	print(decoded)

	var cfg = decoded.split("\n")
	var config = {}
	for c in cfg:
		var parts = c.split(SEPARATOR, 1)
		if parts.size() == 2:
			var key = parts[0].strip_edges()
			var value = parts[1].strip_edges()
			
			#Convert bool properties
			if key in ["only_visible_layers", "wipe_old_anims", "op_exp"]:
				match value:
					"True":
						config[key] = true
					"False":
						config[key] = false
					_:
						config[key] = false
			else:
				config[key] = value
				
	return config

# Public interface for saving and loading configurations

static func load_config(node:Node) -> Dictionary:
	# If the node is not null, load the config from its metadata.
	# Otherwise, load a global config from Popochiu resources (inventory items).
	if node:
		return _load_config_from_meta(node)
	else:
		return _load_config_from_popochiu_resources()


static func save_config(node:Node, cfg:Dictionary) -> void:
	# If the node is not null, save the config to its metadata.
	# Otherwise, save a global config from Popochiu resources (inventory items).
	if node:
		return _save_config_to_meta(node, cfg)
	else:
		return _save_config_to_popochiu_resources(cfg)


static func remove_config(node:Node) -> void:
	# If the node is not null, erase the config from its metadata.
	# Otherwise, erase the global config from Popochiu resources (inventory items).
	if node:
		return _remove_config_from_meta(node)
	else:
		return _remove_config_from_popochiu_resources()


#endregion


#region Private ####################################################################################
static func _load_config_from_meta(node:Node) -> Dictionary:
	# Check if node is not null to avoid showing error messages
	# in Output when inspecting nodes in the Debugger
	if node and node.has_meta(LOCAL_OBJ_CONFIG_META_NAME):
		return node.get_meta(LOCAL_OBJ_CONFIG_META_NAME)

	return {}


static func _save_config_to_meta(node:Node, cfg:Dictionary):
	node.set_meta(LOCAL_OBJ_CONFIG_META_NAME, cfg)


static func _remove_config_from_meta(node:Node):
	if node and node.has_meta(LOCAL_OBJ_CONFIG_META_NAME):
		node.remove_meta(LOCAL_OBJ_CONFIG_META_NAME)


static func _load_config_from_popochiu_resources() -> Dictionary:
	# No need for checks since get_data_value takes a default
	# return value as argument
	return PopochiuResources.get_data_value("importer", "inventory_cfg", {})


static func _save_config_to_popochiu_resources(cfg:Dictionary):
	PopochiuResources.set_data_value("importer", "inventory_cfg", cfg)


static func _remove_config_from_popochiu_resources():
	PopochiuResources.erase_data_value("importer", "inventory_cfg")


static func _decode_base64(string: String):
	if string != "":
		return Marshalls.base64_to_utf8(string)
	return null


static func _is_valid_config(cfg) -> bool:
	return cfg != null and cfg.begins_with(LOCAL_OBJ_CONFIG_MARKER)


#endregion
