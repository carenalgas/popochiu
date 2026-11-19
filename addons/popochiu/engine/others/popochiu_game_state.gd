# @popochiu-docs-category engine
class_name PopochiuGameState
extends RefCounted
## Owns the engine's persistence snapshots for rooms, characters, and inventory items.
##
## The live scene is the runtime source of truth. This class only stores snapshots for objects that
## are not live and builds the save snapshot by merging live objects with those stored snapshots.
##
## Invariants:
## - A live object is never read from its stored snapshot.
## - A room snapshot is invalidated as soon as the room becomes live.
## - [PopochiuRoom.visited_times] is owned by this class and exposed through the room.
## - Room transitions and save/load use the same snapshot service.
## - Snapshots only contain JSON-supported values.

const _ROOM_CHILD_CONTAINERS := {
	"props": "Props",
	"hotspots": "Hotspots",
	"walkable_areas": "WalkableAreas",
	"regions": "Regions",
}
const _ROOM_SNAPSHOT_KEYS := [
	"visited_times",
	"characters",
	"props",
	"hotspots",
	"walkable_areas",
	"regions",
]
const _ITEM_QUANTITY_KEY := "quantity_owned"
const _ITEM_COLLECTED_KEY := "ever_collected"
const _ROOM_CHILD_ENGINE_PROPERTIES := [
	"position",
	"visible",
	"modulate",
	"self_modulate",
]

var _rooms: Dictionary = {}
var _room_visits: Dictionary = {}
var _characters: Dictionary = {}
var _inventory_items: Dictionary = {}
var _live_rooms: Dictionary = {}
var _live_characters: Dictionary = {}
var _live_inventory_items: Dictionary = {}


#region Public #####################################################################################
## Discards every stored snapshot and live reference. Use it when starting a new game.
func clear() -> void:
	clear_snapshots()
	_live_rooms.clear()
	_live_characters.clear()
	_live_inventory_items.clear()


## Discards stored snapshots but keeps live references. Use it before loading save data so the
## loaded snapshots can be applied to objects that are already alive.
func clear_snapshots() -> void:
	_rooms.clear()
	_room_visits.clear()
	_characters.clear()
	_inventory_items.clear()


## Returns [code]true[/code] when [param room_name] has a snapshot for a room that is not live.
func has_room_snapshot(room_name: String) -> bool:
	return _rooms.has(room_name)


## Returns a copy of the stored snapshot for [param room_name], or an empty [Dictionary].
func get_room_snapshot(room_name: String) -> Dictionary:
	var snapshot: Variant = _rooms.get(room_name, {})
	return snapshot.duplicate(true) if snapshot is Dictionary else {}


## Returns how many times the player has visited [param room_name].
func get_room_visited_times(room_name: String) -> int:
	return int(_room_visits.get(room_name, 0))


## Sets how many times the player has visited [param room_name].
func set_room_visited_times(room_name: String, value: int) -> void:
	_room_visits[room_name] = maxi(value, 0)


## Increments the visit counter of [param room_name] and returns the new value.
func increment_room_visits(room_name: String) -> int:
	var visits := get_room_visited_times(room_name) + 1
	_room_visits[room_name] = visits
	return visits


## Captures [param room] while it is live and stores it as an unloaded-room snapshot.
## The live reference is dropped, so the stored snapshot becomes authoritative.
func capture_room(room: PopochiuRoom) -> void:
	if not is_instance_valid(room):
		return

	_rooms[room.script_name] = _build_room_snapshot(room)
	_live_rooms.erase(room.script_name)


## Applies the stored snapshot of [param room], if any, and marks the room as live.
## The snapshot is discarded, so subsequent reads use the live scene.
func apply_room_snapshot(room: PopochiuRoom) -> void:
	if not is_instance_valid(room):
		return

	var snapshot: Variant = _rooms.get(room.script_name, {})
	if snapshot is Dictionary and not snapshot.is_empty():
		_apply_room_snapshot(room, snapshot)

	_rooms.erase(room.script_name)
	_live_rooms[room.script_name] = weakref(room)


## Drops the live reference of [param room_name] without creating a snapshot.
func mark_room_unloaded(room_name: String) -> void:
	_live_rooms.erase(room_name)


## Captures the persistent state of [param character] as a snapshot for an unloaded character.
func capture_character(character: PopochiuCharacter) -> void:
	if not is_instance_valid(character):
		return

	_characters[character.script_name] = _build_character_snapshot(character)
	_live_characters.erase(character.script_name)


## Applies the stored snapshot of [param character], if any, and marks it as live.
func apply_character_snapshot(character: PopochiuCharacter) -> void:
	if not is_instance_valid(character):
		return

	var character_name: String = character.script_name
	var snapshot: Variant = _characters.get(character_name, {})
	if snapshot is Dictionary and not snapshot.is_empty():
		PopochiuResources.restore_custom_properties(character, snapshot)

	_characters.erase(character_name)
	_live_characters[character_name] = weakref(character)


## Captures the persistent state of [param item] as a snapshot for an unloaded inventory item.
func capture_inventory_item(item: PopochiuInventoryItem) -> void:
	if not is_instance_valid(item):
		return

	_inventory_items[item.script_name] = _build_inventory_item_snapshot(item)
	_live_inventory_items.erase(item.script_name)


## Applies the stored snapshot of [param item], if any, and marks it as live.
func apply_inventory_item_snapshot(item: PopochiuInventoryItem) -> void:
	if not is_instance_valid(item):
		return

	var item_name: String = item.script_name
	var snapshot: Variant = _inventory_items.get(item_name, {})
	if snapshot is Dictionary and not snapshot.is_empty():
		var custom_properties: Dictionary = snapshot.duplicate(true)
		custom_properties.erase(_ITEM_QUANTITY_KEY)
		custom_properties.erase(_ITEM_COLLECTED_KEY)
		PopochiuResources.restore_custom_properties(item, custom_properties)

		if snapshot.has(_ITEM_QUANTITY_KEY):
			item.quantity_owned = int(snapshot[_ITEM_QUANTITY_KEY])
		if snapshot.has(_ITEM_COLLECTED_KEY):
			item.ever_collected = bool(snapshot[_ITEM_COLLECTED_KEY])

	_inventory_items.erase(item_name)
	_live_inventory_items[item_name] = weakref(item)


## Builds the current object snapshot, merging live objects with stored snapshots.
## The returned [Dictionary] has the [code]rooms[/code], [code]characters[/code], and
## [code]inventory_items[/code] sections used by save/load.
func get_snapshot() -> Dictionary:
	_prune_live_refs()

	var rooms_snapshot := _rooms.duplicate(true)
	for room_name: String in _live_rooms:
		var room: PopochiuRoom = _get_live_object(_live_rooms[room_name])
		if is_instance_valid(room):
			rooms_snapshot[room_name] = _build_room_snapshot(room)

	var characters_snapshot := _characters.duplicate(true)
	for character_name: String in _live_characters:
		var character: PopochiuCharacter = _get_live_object(
			_live_characters[character_name]
		)
		if is_instance_valid(character):
			characters_snapshot[character_name] = _build_character_snapshot(character)

	var inventory_items_snapshot := _inventory_items.duplicate(true)
	for item_name: String in _live_inventory_items:
		var item: PopochiuInventoryItem = _get_live_object(
			_live_inventory_items[item_name]
		)
		if is_instance_valid(item):
			inventory_items_snapshot[item_name] = _build_inventory_item_snapshot(item)

	_prune_empty_snapshots(characters_snapshot)
	_prune_empty_snapshots(inventory_items_snapshot)

	return {
		rooms = rooms_snapshot,
		characters = characters_snapshot,
		inventory_items = inventory_items_snapshot,
	}


## Loads object snapshots from a save file, including saves produced before this service existed.
## Live objects with a stored snapshot receive it immediately. Snapshots for objects that are not
## live are applied when those objects are instantiated.
func load_snapshot(snapshot: Dictionary) -> void:
	clear_snapshots()
	_live_rooms.clear()

	var rooms_snapshot: Variant = snapshot.get("rooms", {})
	if rooms_snapshot is Dictionary:
		for room_name: String in rooms_snapshot:
			var room_snapshot: Variant = rooms_snapshot[room_name]
			if not room_snapshot is Dictionary:
				continue

			_rooms[room_name] = room_snapshot.duplicate(true)
			_room_visits[room_name] = int(room_snapshot.get("visited_times", 0))

	var characters_snapshot: Variant = snapshot.get("characters", {})
	if characters_snapshot is Dictionary:
		for character_name: String in characters_snapshot:
			var character_snapshot: Variant = characters_snapshot[character_name]
			if character_snapshot is Dictionary:
				_characters[character_name] = character_snapshot.duplicate(true)

	var inventory_items_snapshot: Variant = snapshot.get("inventory_items", {})
	if inventory_items_snapshot is Dictionary:
		for item_name: String in inventory_items_snapshot:
			var item_snapshot: Variant = inventory_items_snapshot[item_name]
			if item_snapshot is Dictionary:
				_inventory_items[item_name] = item_snapshot.duplicate(true)

	_apply_pending_snapshots_to_live_objects()


#endregion

#region Private ####################################################################################
func _build_room_snapshot(room: PopochiuRoom) -> Dictionary:
	var snapshot := {}
	PopochiuResources.store_custom_properties(snapshot, room)
	snapshot.visited_times = get_room_visited_times(room.script_name)
	snapshot.characters = _build_room_characters_snapshot(room)

	for category: String in _ROOM_CHILD_CONTAINERS:
		snapshot[category] = _build_room_children_snapshot(room, category)

	return snapshot


func _build_room_children_snapshot(room: PopochiuRoom, category: String) -> Dictionary:
	var snapshot := {}
	var container: Node = room.get_node_or_null(_ROOM_CHILD_CONTAINERS[category])
	if not is_instance_valid(container):
		return snapshot

	var ignore: Array = PopochiuResources["%s_IGNORE" % category.to_upper()]

	for child: Node in container.get_children():
		if not _is_room_child_of_type(child, category):
			continue
		if child is PopochiuProp and not child.clickable:
			continue

		var child_name := _get_object_name(child)
		if child_name.is_empty():
			continue

		var state := {}
		PopochiuResources.store_properties(state, child, ignore)
		_capture_child_engine_properties(state, child)
		snapshot[child_name] = state

	return snapshot


func _is_room_child_of_type(child: Node, category: String) -> bool:
	match category:
		"props":
			return child is PopochiuProp
		"hotspots":
			return child is PopochiuHotspot
		"walkable_areas":
			return child is PopochiuWalkableArea
		"regions":
			return child is PopochiuRegion

	return false


func _capture_child_engine_properties(state: Dictionary, child: Node) -> void:
	if not child is Node2D:
		return

	var child_2d := child as Node2D
	state.position = { x = child_2d.position.x, y = child_2d.position.y }
	state.visible = child_2d.visible
	state.modulate = child_2d.modulate.to_html()
	state.self_modulate = child_2d.self_modulate.to_html()


func _build_room_characters_snapshot(room: PopochiuRoom) -> Dictionary:
	var snapshot := {}

	for character: PopochiuCharacter in room.get_characters():
		snapshot[character.script_name] = {
			x = character.position.x,
			y = character.position.y,
			facing = character._looking_dir,
			visible = character.visible,
			modulate = character.modulate.to_html(),
			self_modulate = character.self_modulate.to_html(),
			light_mask = character.light_mask,
			baseline = character.baseline,
			walk_to_point = {
				x = character.walk_to_point.x,
				y = character.walk_to_point.y,
			},
			look_at_point = {
				x = character.look_at_point.x,
				y = character.look_at_point.y,
			},
			dialog_pos = {
				x = character.dialog_pos.x,
				y = character.dialog_pos.y,
			},
			face_character = character.face_character,
			follow_character = character.follow_character,
			follow_character_outside_room = character.follow_character_outside_room,
			follow_character_offset = {
				x = character.follow_character_offset.x,
				y = character.follow_character_offset.y,
			},
			follow_character_threshold = {
				x = character.follow_character_threshold.x,
				y = character.follow_character_threshold.y,
			},
		}

	return snapshot


func _build_character_snapshot(character: PopochiuCharacter) -> Dictionary:
	var snapshot := {}
	PopochiuResources.store_custom_properties(snapshot, character)
	return snapshot


func _build_inventory_item_snapshot(item: PopochiuInventoryItem) -> Dictionary:
	var snapshot := {}
	PopochiuResources.store_custom_properties(snapshot, item)

	if item.quantity_owned > 0:
		snapshot[_ITEM_QUANTITY_KEY] = item.quantity_owned
	if item.ever_collected:
		snapshot[_ITEM_COLLECTED_KEY] = true

	return snapshot


func _apply_room_snapshot(room: PopochiuRoom, snapshot: Dictionary) -> void:
	PopochiuResources.restore_custom_properties(
		room, _extract_room_custom_properties(snapshot)
	)
	_room_visits[room.script_name] = int(snapshot.get("visited_times", 0))

	for category: String in _ROOM_CHILD_CONTAINERS:
		var children_snapshot: Variant = snapshot.get(category, {})
		if not children_snapshot is Dictionary:
			continue

		for child_name: String in children_snapshot:
			var child := _find_room_child(room, category, child_name)
			if not is_instance_valid(child):
				continue

			var properties: Variant = children_snapshot[child_name]
			if not properties is Dictionary:
				continue

			for property_name: String in properties:
				if not _has_restorable_property(child, property_name):
					continue

				_restore_node_property(child, property_name, properties[property_name])

	var characters_snapshot: Variant = snapshot.get("characters", {})
	if characters_snapshot is Dictionary:
		_apply_room_characters_snapshot(room, characters_snapshot)


func _apply_room_characters_snapshot(room: PopochiuRoom, snapshot: Dictionary) -> void:
	for character_name: String in snapshot:
		var character_state: Variant = snapshot[character_name]
		if not character_state is Dictionary:
			continue

		var character: PopochiuCharacter = PopochiuUtils.c.get_character(character_name)
		if not is_instance_valid(character):
			continue

		if character.is_inside_tree():
			var parent := character.get_parent()
			if parent:
				parent.remove_child(character)

		character.position = Vector2(character_state.x, character_state.y)
		character._looking_dir = int(character_state.facing)
		character.visible = bool(character_state.visible)
		character.modulate = Color.from_string(character_state.modulate, Color.WHITE)
		character.self_modulate = Color.from_string(
			character_state.self_modulate, Color.WHITE
		)
		character.light_mask = int(character_state.light_mask)
		character.baseline = int(character_state.baseline)

		if character_state.has("walk_to_point"):
			character.walk_to_point = PopochiuUtils.unpack_vector_2(
				character_state.walk_to_point
			)

		if character_state.has("look_at_point"):
			character.look_at_point = PopochiuUtils.unpack_vector_2(
				character_state.look_at_point
			)

		if character_state.has("dialog_pos"):
			character.dialog_pos = PopochiuUtils.unpack_vector_2(character_state.dialog_pos)

		if character_state.has("follow_character_outside_room"):
			character.follow_character_outside_room = bool(
				character_state.follow_character_outside_room
			)

		if character_state.has("follow_character_offset"):
			character.follow_character_offset = PopochiuUtils.unpack_vector_2(
				character_state.follow_character_offset
			)

		if character_state.has("follow_character_threshold"):
			character.follow_character_threshold = PopochiuUtils.unpack_vector_2(
				character_state.follow_character_threshold
			)

		if character_state.has("face_character") and character_state.face_character:
			character.face_character = character_state.face_character

		if character_state.has("follow_character") and character_state.follow_character:
			character.follow_character = character_state.follow_character

		room.add_character(character)

		if not character.face_character.is_empty():
			var faced_character := PopochiuUtils.c.get_character(character.face_character)
			if is_instance_valid(faced_character) and faced_character.is_inside_tree():
				character.start_facing_character(faced_character)

		if not character.follow_character.is_empty():
			var followed_character := PopochiuUtils.c.get_character(
				character.follow_character
			)
			if (
				is_instance_valid(followed_character)
				and followed_character.is_inside_tree()
			):
				character.start_following_character(followed_character)


func _extract_room_custom_properties(snapshot: Dictionary) -> Dictionary:
	var custom_properties: Dictionary = snapshot.duplicate(true)
	for key: String in _ROOM_SNAPSHOT_KEYS:
		custom_properties.erase(key)

	return custom_properties


func _find_room_child(room: PopochiuRoom, category: String, child_name: String) -> Node2D:
	var container: Node = room.get_node_or_null(_ROOM_CHILD_CONTAINERS[category])
	if not is_instance_valid(container):
		return null

	for child: Node in container.get_children():
		if not child is Node2D:
			continue
		if not _is_room_child_of_type(child, category):
			continue
		if _get_object_name(child) == child_name or child.name == child_name:
			return child as Node2D

	return null


func _get_object_name(node: Node) -> String:
	var value: Variant = node.get("script_name")
	if value is String and not value.is_empty():
		return value

	return String(node.name)


func _has_restorable_property(node: Node2D, property: String) -> bool:
	return property in _ROOM_CHILD_ENGINE_PROPERTIES or PopochiuResources.has_property(
		node, property
	)


func _restore_node_property(node: Node2D, property: String, value: Variant) -> void:
	var current_value: Variant = node[property]

	if current_value is Vector2 and value is Dictionary:
		node[property] = Vector2(value.x, value.y)
		return

	if current_value is Color and value is String:
		node[property] = Color.from_string(value, current_value)
		return

	if current_value is Array:
		var destination: Array = current_value

		if value is Array:
			destination.assign(value)
			return

		if value is PackedVector2Array:
			destination.assign([value])
			return

		node[property] = value
		return

	if current_value is PackedVector2Array and value is Array:
		node[property] = PackedVector2Array(value)
		return

	node[property] = value


func _apply_pending_snapshots_to_live_objects() -> void:
	var applied_characters := {}
	var characters := PopochiuUtils.c.get_characters()
	for character: PopochiuCharacter in characters.values():
		if is_instance_valid(character) and _characters.has(character.script_name):
			applied_characters[character.script_name] = true
			apply_character_snapshot(character)

	for character_name: String in _live_characters.keys():
		if applied_characters.has(character_name):
			continue
		var character: PopochiuCharacter = _get_live_object(
			_live_characters[character_name]
		)
		if is_instance_valid(character) and _characters.has(character_name):
			apply_character_snapshot(character)

	var player := PopochiuUtils.c.player
	if is_instance_valid(player) and _characters.has(player.script_name):
		apply_character_snapshot(player)

	for item_name: String in _inventory_items.keys():
		var item := PopochiuUtils.i.get_item_instance(item_name)
		if is_instance_valid(item):
			apply_inventory_item_snapshot(item)


func _get_live_object(reference: Variant) -> Object:
	if reference is WeakRef:
		return reference.get_ref()

	return null


func _prune_live_refs() -> void:
	_prune_refs(_live_rooms)
	_prune_refs(_live_characters)
	_prune_refs(_live_inventory_items)


func _prune_empty_snapshots(snapshots: Dictionary) -> void:
	for object_name: String in snapshots.keys():
		var snapshot: Variant = snapshots[object_name]
		if snapshot is Dictionary and snapshot.is_empty():
			snapshots.erase(object_name)


func _prune_refs(references: Dictionary) -> void:
	for object_name: String in references.keys():
		if not is_instance_valid(_get_live_object(references[object_name])):
			references.erase(object_name)


#endregion
