@tool
class_name PopochiuAsepriteTagGrouper
extends RefCounted

# Detects and validates "group tags" in the list of Aseprite tags of a file.
#
# A tag is a group when its frame range fully contains other tags and its name
# is a case-insensitive prefix of all of them (CamelCase or snake_case). A group
# is imported as a single prop with one animation per child tag, named after the
# child with the group prefix stripped (e.g. group "Door" + tags "DoorClose" and
# "DoorOpen" -> prop "Door" with animations "close" and "open").
#
# Any misconfiguration (a contained tag that doesn't follow the naming, nested
# groups, etc.) invalidates the whole cluster: the importer must skip it and
# report the problem instead of guessing.


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Analyzes a list of tags (each with tag_name/from/to/direction) and returns:
# {
#   groups: [ { name, from, to, direction, children: [{tag_name, anim_name, from, to, direction}], is_valid, error } ],
#   singles: [ { tag_name, from, to, direction } ],
#   errors: [ String, ... ]
#   warnings: [ String, ... ],
# }
func analyze(tags: Array) -> Dictionary:
	var result := {
		"groups": [],
		"singles": [],
		"errors": [],
		"warnings": [],
	}

	# Only tags with a usable frame range can take part in a group. Ranges can
	# arrive as int or float (Godot's JSON parser may produce floats), so they
	# are normalized to int here.
	var ranged := []
	for tag in tags:
		var tag_from = tag.get("from")
		var tag_to = tag.get("to")
		if (
			typeof(tag_from) in [TYPE_INT, TYPE_FLOAT]
			and typeof(tag_to) in [TYPE_INT, TYPE_FLOAT]
			and int(tag_from) >= 0
			and int(tag_to) >= int(tag_from)
		):
			var ranged_tag: Dictionary = tag.duplicate()
			ranged_tag.from = int(tag_from)
			ranged_tag.to = int(tag_to)
			ranged.push_back(ranged_tag)

	# Compute which tags are fully contained in the range of each tag
	var contained_by := {}
	for tag in ranged:
		contained_by[tag.tag_name] = []
	for outer in ranged:
		for inner in ranged:
			if inner.tag_name == outer.tag_name:
				continue
			# A tag with the exact same range is not "inside" another one: with
			# identical ranges every tag would contain every other, making them
			# all "claimed" and dropping them from the list.
			if inner.from == outer.from and inner.to == outer.to:
				continue
			if outer.from <= inner.from and inner.to <= outer.to:
				contained_by[outer.tag_name].push_back(inner)

	# Tags contained in at least one other tag belong to a cluster: they must not
	# be offered as standalone tags (they are either group children or blocked
	# with their group)
	var claimed := {}
	for tag in ranged:
		for inner in contained_by.get(tag.tag_name, []):
			claimed[inner.tag_name] = true

	# Group candidates are tags that contain others. A candidate that is itself
	# contained in another tag (nested group) is rendered as part of its parent's
	# cluster, never as its own group.
	var group_candidates := []
	for tag in ranged:
		if contained_by.get(tag.tag_name, []).is_empty():
			continue
		if claimed.has(tag.tag_name):
			continue
		group_candidates.push_back(tag)

	for tag in group_candidates:
		var group := {
			"name": tag.tag_name,
			"from": tag.from,
			"to": tag.to,
			"direction": tag.direction,
			"children": [],
			"is_valid": true,
			"error": "",
		}
		var errors := []

		for child in contained_by.get(tag.tag_name, []):
			# Nested groups are not supported: a child cannot span other tags itself
			if not contained_by.get(child.tag_name, []).is_empty():
				errors.append(
					"Tag '%s' contains other tags. Nested groups are not supported." % child.tag_name
				)
				continue

			# The child name must follow the group naming convention
			var anim_name := strip_prefix(child.tag_name, tag.tag_name)
			if anim_name.is_empty():
				errors.append(
					"Tag '%s' is inside the range of '%s' but does not follow the naming convention "
					% [child.tag_name, tag.tag_name]
					+ "(it must start with '%s' and have a distinct name, e.g. '%sClose')."
					% [tag.tag_name, tag.tag_name]
				)
				continue

			group.children.push_back({
				"tag_name": child.tag_name,
				"anim_name": anim_name,
				"from": child.from,
				"to": child.to,
				"direction": child.direction,
			})

		# A tag that follows the group naming but is only partially inside the
		# group's range means the group doesn't encompass all its animations.
		# Such tags belong to the cluster and must not be imported standalone.
		for other in ranged:
			if other.tag_name == tag.tag_name:
				continue
			if not _matches_prefix(other.tag_name, tag.tag_name):
				continue
			if _is_contained(other, tag, contained_by):
				continue
			if other.from <= tag.to and tag.from <= other.to:
				claimed[other.tag_name] = true
				errors.append(
					"Tag '%s' follows the group naming of '%s' but is only partially inside its range "
					% [other.tag_name, tag.tag_name]
					+ "(%d-%d). The group must fully encompass all its animations." % [tag.from, tag.to]
				)

		if errors.is_empty():
			_check_group_gaps(result, group)
			result.groups.push_back(group)
		else:
			group.is_valid = false
			group.error = " ".join(errors)
			result.errors.append(group.error)
			result.groups.push_back(group)

	# Tags that don't belong to any cluster are standalone. Iterate the FULL tag
	# list (not just ranged ones): when frame ranges are unavailable the tags
	# still render as a flat list, so a failed range fetch never empties the list.
	for tag in tags:
		if claimed.has(tag.tag_name) or not contained_by.get(tag.tag_name, []).is_empty():
			continue
		result.singles.push_back(tag)

	return result


# Returns the animation name for a child tag of a group (prefix stripped and
# snake_cased), or an empty string when the name doesn't follow the convention.
# A word boundary is required after the prefix so that names that merely share a
# prefix (e.g. "Doors" inside "Door") are not treated as children.
func strip_prefix(child_name: String, group_name: String) -> String:
	var lower_child := child_name.to_lower()
	var lower_group := group_name.to_lower()

	if not lower_child.begins_with(lower_group):
		return ""

	# A tag with the exact same name (case-insensitive) is not a child
	if child_name.length() == group_name.length():
		return ""

	# Require a separator or an uppercase letter right after the prefix
	var next_char := child_name.substr(group_name.length(), 1)
	if not (next_char == "_" or next_char == " " or _is_uppercase(next_char)):
		return ""

	var remainder := child_name.substr(group_name.length())
	remainder = remainder.trim_prefix("_").trim_prefix(" ")
	return remainder.to_snake_case()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
# Whether the child name follows the group naming convention.
func _matches_prefix(child_name: String, group_name: String) -> bool:
	return not strip_prefix(child_name, group_name).is_empty()


# Whether [param inner] is fully contained in [param outer]'s range.
func _is_contained(inner: Dictionary, outer: Dictionary, contained_by: Dictionary) -> bool:
	for c in contained_by.get(outer.tag_name, []):
		if c.tag_name == inner.tag_name:
			return true
	return false


# Emits a warning when frames inside the group's range are not covered by any
# child animation. The group is still imported (gaps are tolerated).
func _check_group_gaps(result: Dictionary, group: Dictionary) -> void:
	var children: Array = group.get("children", [])
	if children.is_empty():
		return

	children.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.from < b.from)

	var uncovered := []
	var cursor: int = group.from
	for child in children:
		if child.from > cursor:
			uncovered.push_back([cursor, child.from - 1])
		if child.to + 1 > cursor:
			cursor = child.to + 1
	if cursor <= group.to:
		uncovered.push_back([cursor, group.to])

	if not uncovered.is_empty():
		var ranges := []
		for r in uncovered:
			ranges.append("%d-%d" % [r[0], r[1]])
		result.warnings.append(
			"Aseprite importer: Group '%s' has frames not covered by any animation: %s. "
			% [group.name, ", ".join(ranges)]
			+ "They will be ignored."
		)


func _is_uppercase(char: String) -> bool:
	return char != "" and char == char.to_upper() and char != char.to_lower()
