@tool
extends RefCounted


const LOCAL_OBJ_CONFIG_META_NAME = "_popochiu_aseprite_config_"
const LOCAL_OBJ_CONFIG_MARKER = "popochiu_aseprite_config"
const SEPARATOR = "|="



# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
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


static func load_config(node:Node):
	# Check if node is not null to avoid showing error messages in Output when inspecting nodes in
	# the Debugger
	if node and node.has_meta(LOCAL_OBJ_CONFIG_META_NAME):
		return node.get_meta(LOCAL_OBJ_CONFIG_META_NAME)


static func save_config(node:Node, cfg:Dictionary):
	node.set_meta(LOCAL_OBJ_CONFIG_META_NAME, cfg)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
static func _decode_base64(string: String):
	if string != "":
		return Marshalls.base64_to_utf8(string)
	return null


static func _is_valid_config(cfg) -> bool:
	return cfg != null and cfg.begins_with(LOCAL_OBJ_CONFIG_MARKER)
