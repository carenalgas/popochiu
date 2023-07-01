extends Resource

# This class holds logic to help with the management of Popochiu objects.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓


# Functions used to know the type of a Node (or group of Nodes) when this type of
# validation is required from the plugin.
static func is_prop(node: Node) -> bool:
	return node is PopochiuProp


static func is_hotspot(node: Node) -> bool:
	return node is PopochiuHotspot


static func is_character(node: Node) -> bool:
	return node is PopochiuCharacter


static func is_walkable_area(node: Node) -> bool:
	return node is PopochiuWalkableArea

## TODO: provide more helpers like this maybe?


# Functions used to create Popochiu objects of various types.
# They are designed to be used from the Editor plugin, not the Engine code.
static func create_character():
	pass


static func create_dialog():
	pass


static func create_hotspot():
	pass


static func create_inventory_item():
	pass


static func create_prop():
	pass


static func create_region():
	pass


static func create_room():
	pass


static func create_walkable_area():
	pass
