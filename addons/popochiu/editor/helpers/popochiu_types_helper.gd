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

## TODO: If and when #67 is ready, add static facade metods to create items
## so we can just pass this object as entry point for all operations
## on Popochiu objects
