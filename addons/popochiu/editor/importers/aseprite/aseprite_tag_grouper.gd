@tool
class_name PopochiuAsepriteTagGrouper
extends RefCounted

# Groups Aseprite tags using an EXPLICIT prefix convention (no guessing):
#   "@Door"            -> a group tag. The prop will be named "Door". The group
#                         tag's own frame range is the group's SPAN: it is used
#                         both to export the group spritesheet and to validate
#                         that every ":..." animation is fully inside it.
#   ":DoorClosed"      -> an animation of group "Door", named "closed".
#   plain tags         -> standalone single-animation props (unchanged behavior).
#
# Association is by NAME: ":DoorClosed" belongs to "@Door". The "@" and ":"
# characters are reserved for this convention. Misconfigurations are reported
# as errors or warnings instead of being silently guessed.
#
# When frame ranges are available (fetched at scan time for files with group
# tags), the grouper also validates that every animation is fully inside its
# group's span, and the safety net only warns for plain tags that actually fall
# inside a group's span.


const GROUP_PREFIX := "@"
const ANIM_PREFIX := ":"


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
# Analyzes a list of tags (each with tag_name, and optionally from/to/direction)
# and returns:
# {
#   items: [ {kind:"group", ...} | {kind:"single", tag:{...}} ],  # source order
#   groups: [...],    # the group entries (same objects as in items)
#   singles: [...],   # the plain tag dicts
#   errors: [String, ...],
#   warnings: [String, ...],
# }
func analyze(tags: Array) -> Dictionary:
	var result := {
		"items": [],
		"groups": [],
		"singles": [],
		"errors": [],
		"warnings": [],
	}

	var group_names := {}  # lower(name) -> display name ("Door")
	var group_spans := {}  # lower(name) -> {from, to} of the @ tag, or null
	var group_name_count := {}  # lower(name) -> how many @ tags share it
	for tag in tags:
		var name: String = tag.get("tag_name", "")
		if not name.begins_with(GROUP_PREFIX):
			continue
		if name.length() == 1:
			result.errors.append(
				"Aseprite importer: tag '%s' is not a valid group tag (missing name)." % name
			)
			continue
		var display := name.substr(1)
		var lower := display.to_lower()
		group_names[lower] = display
		group_name_count[lower] = group_name_count.get(lower, 0) + 1
		var tag_from = tag.get("from")
		var tag_to = tag.get("to")
		if (
			typeof(tag_from) in [TYPE_INT, TYPE_FLOAT]
			and typeof(tag_to) in [TYPE_INT, TYPE_FLOAT]
			and int(tag_from) >= 0
			and int(tag_to) >= int(tag_from)
		):
			group_spans[lower] = { "from": int(tag_from), "to": int(tag_to) }
		else:
			group_spans[lower] = null

	# Duplicate group names (case-insensitive) are ambiguous and must be fixed
	var duplicate_groups := {}
	for lower in group_name_count:
		if group_name_count[lower] > 1:
			duplicate_groups[lower] = true
			result.errors.append(
				"Aseprite importer: multiple group tags are named '%s' (case-insensitive). "
				% group_names[lower]
				+ "Rename them so each group name is unique."
			)

	# Associate every ":..." tag with its group by name (longest match wins)
	var anims_by_group := {}  # lower(group name) -> [ {tag, anim_name} ]
	for tag in tags:
		var name: String = tag.get("tag_name", "")
		if not name.begins_with(ANIM_PREFIX):
			continue
		if name.length() == 1:
			result.errors.append(
				"Aseprite importer: tag '%s' is not a valid animation tag (missing name)." % name
			)
			continue

		var remainder := name.substr(1)
		var matched_lower := _find_matching_group(remainder, group_names, duplicate_groups, false)

		if matched_lower.is_empty():
			# Give a more precise message when the animation is named after a group
			var looked_like_group := false
			for lower in group_names:
				if remainder.to_lower() == lower:
					looked_like_group = true
					break
			if looked_like_group:
				result.errors.append(
					"Aseprite importer: animation tag '%s' has no animation name after the group prefix." % name
				)
			else:
				result.errors.append(
					"Aseprite importer: animation tag '%s' has no matching group. "
					% name
					+ "Expected ':GroupNameAnimation' with a corresponding '@GroupName' tag."
				)
			continue

		if not anims_by_group.has(matched_lower):
			anims_by_group[matched_lower] = []
		anims_by_group[matched_lower].append({
			"tag": tag,
			"anim_name": _strip_group_from_name(remainder, matched_lower),
		})

	# Build the group entries in source order
	var groups_by_tag := {}
	for tag in tags:
		var name: String = tag.get("tag_name", "")
		if not name.begins_with(GROUP_PREFIX):
			continue
		if name.length() == 1:
			continue  # already reported
		var display := name.substr(1)
		var lower := display.to_lower()
		if duplicate_groups.has(lower):
			continue  # already reported

		var anims := anims_by_group.get(lower, [])
		if anims.is_empty():
			result.warnings.append(
				"Aseprite importer: group '%s' has no animations. "
				% display
				+ "Add ':...' tags for it (e.g. ':%sClosed') or remove the '@%s' tag." % [display, display]
			)
			continue

		var group := {
			"kind": "group",
			"tag_name": name,
			"name": display,
			"from": -1,
			"to": -1,
			"direction": "forward",
			"children": [],
			"is_valid": true,
			"error": "",
		}
		# The group's own frame range is the SPAN: it drives both the export
		# range and the validation (animations must be fully inside it).
		var span: Dictionary = group_spans.get(lower)
		if span != null:
			group.from = span.from
			group.to = span.to

		var errors := []
		for anim in anims:
			var child := {
				"tag_name": anim.tag.tag_name,
				"anim_name": anim.anim_name,
			}
			var cf = anim.tag.get("from")
			var ct = anim.tag.get("to")
			if typeof(cf) in [TYPE_INT, TYPE_FLOAT] and typeof(ct) in [TYPE_INT, TYPE_FLOAT]:
				child.from = int(cf)
				child.to = int(ct)
				child.direction = anim.tag.get("direction", "forward")
				# The group span must fully cover every animation. Frame numbers
				# are shown 1-based to match the Aseprite editor UI.
				if group.from < 0 or child.from < group.from or child.to > group.to:
					errors.append(
						"Aseprite importer: group '@%s' does not fully cover its animation '%s' "
						% [display, child.tag_name]
						+ "(group spans %d-%d, animation spans %d-%d). "
						% [group.from + 1, group.to + 1, child.from + 1, child.to + 1]
						+ "Extend the group tag range or move the animation inside it."
					)
			group.children.append(child)

		if group.from < 0:
			errors.append(
				"Aseprite importer: group '@%s' has no usable frame range." % name
			)

		if errors.is_empty():
			_check_group_gaps(result, group)
		else:
			group.is_valid = false
			group.error = " ".join(errors)
			result.errors.append(group.error)

		result.groups.append(group)
		groups_by_tag[name] = group

	# Safety net: a plain tag that matches a group name and falls inside the
	# group's span probably means a forgotten ':' prefix. Plain tags outside
	# the span are legit separate props.
	for tag in tags:
		var name: String = tag.get("tag_name", "")
		if name.begins_with(GROUP_PREFIX) or name.begins_with(ANIM_PREFIX):
			continue
		var matched_lower := _find_matching_group(name, group_names, duplicate_groups, true)
		if matched_lower.is_empty():
			continue
		var span: Dictionary = group_spans.get(matched_lower)
		if span != null and not _is_fully_inside(tag, span):
			continue  # outside the group's span: a legit separate prop
		result.warnings.append(
			"Aseprite importer: plain tag '%s' matches group '%s'%s. Did you forget the ':' prefix?"
			% [name, group_names[matched_lower], "" if span == null else " and is inside its range"]
		)

	# Build the ordered item list and the standalone singles
	for tag in tags:
		var name: String = tag.get("tag_name", "")
		if name.begins_with(GROUP_PREFIX):
			if groups_by_tag.has(name):
				result.items.append(groups_by_tag[name])
			continue
		if name.begins_with(ANIM_PREFIX):
			continue
		result.singles.append(tag)
		result.items.append({ "kind": "single", "tag": tag })

	return result


# Returns the animation name for a ":GroupAnim" tag (group prefix stripped and
# snake_cased), or an empty string when the name doesn't follow the convention.
# The name must begin with the group name, and a word boundary is required right
# after it so that names that merely share a prefix (e.g. "Doors" under group
# "Door", or unrelated names like "TestAnim" under "Door") are not matched.
func _strip_group_from_name(remainder: String, lower_group: String) -> String:
	if not remainder.to_lower().begins_with(lower_group):
		return ""
	if remainder.to_lower() == lower_group:
		return ""
	var next_char := remainder.substr(lower_group.length(), 1)
	if not (next_char == "_" or next_char == " " or _is_uppercase(next_char)):
		return ""
	var rest := remainder.substr(lower_group.length()).trim_prefix("_").trim_prefix(" ")
	return rest.to_snake_case()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
# Returns the lower-cased name of the longest group that [param remainder]
# matches (case-insensitive, with a word boundary after the group name), or ""
# when none matches. [param allow_exact] also accepts a name that is exactly the
# group name (used by the safety net, not by the animation association).
func _find_matching_group(remainder: String, group_names: Dictionary, duplicate_groups: Dictionary, allow_exact: bool) -> String:
	var matched_lower := ""
	var matched_display := ""
	for lower in group_names:
		if duplicate_groups.has(lower):
			continue
		if not remainder.to_lower().begins_with(lower):
			continue
		if group_names[lower].length() <= matched_display.length():
			continue
		if (
			_strip_group_from_name(remainder, lower).is_empty()
			and not (allow_exact and remainder.to_lower() == lower)
		):
			continue
		matched_lower = lower
		matched_display = group_names[lower]
	return matched_lower


# Whether the tag's frame range is fully inside the given span.
func _is_fully_inside(tag: Dictionary, span: Dictionary) -> bool:
	var tag_from = tag.get("from")
	var tag_to = tag.get("to")
	if typeof(tag_from) not in [TYPE_INT, TYPE_FLOAT] or typeof(tag_to) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	return span.from <= int(tag_from) and int(tag_to) <= span.to


# Emits a warning when frames inside the group's span are not covered by any
# child animation. The group is still imported (gaps are tolerated).
func _check_group_gaps(result: Dictionary, group: Dictionary) -> void:
	if group.get("from", -1) < 0 or group.get("to", -1) < group.get("from", -1):
		return
	var children: Array = group.get("children", [])
	var ranged_children := []
	for child in children:
		if child.has("from") and child.has("to"):
			ranged_children.append(child)
	if ranged_children.is_empty():
		return

	ranged_children.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.from < b.from)

	var uncovered := []
	var cursor: int = group.from
	for child in ranged_children:
		if child.from > cursor:
			uncovered.push_back([cursor, child.from - 1])
		if child.to + 1 > cursor:
			cursor = child.to + 1
	if cursor <= group.to:
		uncovered.push_back([cursor, group.to])

	if not uncovered.is_empty():
		var ranges := []
		for r in uncovered:
			# Frame numbers are shown 1-based to match the Aseprite editor UI
			ranges.append("%d-%d" % [r[0] + 1, r[1] + 1])
		result.warnings.append(
			"Aseprite importer: Group '%s' has frames not covered by any animation: %s. "
			% [group.name, ", ".join(ranges)]
			+ "They will be ignored."
		)


func _is_uppercase(char: String) -> bool:
	return char != "" and char == char.to_upper() and char != char.to_lower()
