@tool
class_name PopochiuTranslationParserPlugin
extends EditorTranslationParserPlugin
# Extracts translatable strings from Popochiu game scripts by scanning for known function calls
# (say, show_system_text, etc.) and dialog option text assignments.
# Runs alongside Godot's native GDScript parser — does not replace it.

const DEFAULT_FUNCTION_NAMES: PackedStringArray = [
	"say",
	"queue_say",
	"show_system_text",
	"queue_show_system_text",
	"show_hover_text",
]

var _function_regex: RegEx
var _non_literal_regex: RegEx
var _text_assignment_regex: RegEx


#region Godot ######################################################################################
func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["gd"])


func _parse_file(path: String) -> Array[PackedStringArray]:
	if not _is_in_scan_paths(path):
		return []

	_compile_regexes()

	return _extract_strings_from_file(path)


#endregion

#region Godot 4.7 — uncomment when _customize_strings() becomes available ########################
## Called after all files have been parsed. Scans target paths and appends extracted strings.
#func _customize_strings(strings: Array[PackedStringArray]) -> Array[PackedStringArray]:
#	_compile_regexes()
#
#	var scan_paths := _get_scan_paths()
#	for scan_path in scan_paths:
#		var files := _get_gd_files_in_path(scan_path)
#		for file_path in files:
#			var extracted := _extract_strings_from_file(file_path)
#			strings.append_array(extracted)
#
#	return strings
#
#
#func _get_gd_files_in_path(path: String) -> PackedStringArray:
#	var files: PackedStringArray = []
#	var dir := DirAccess.open(path)
#	if not dir:
#		return files
#
#	dir.list_dir_begin()
#	var file_name := dir.get_next()
#	while file_name != "":
#		var full_path := path.path_join(file_name)
#		if dir.current_is_dir():
#			files.append_array(_get_gd_files_in_path(full_path))
#		elif file_name.get_extension() == "gd":
#			files.append(full_path)
#		file_name = dir.get_next()
#	dir.list_dir_end()
#
#	return files
#endregion

#region Private ####################################################################################
func _is_in_scan_paths(path: String) -> bool:
	var scan_paths := _get_scan_paths()
	for scan_path in scan_paths:
		if path.begins_with(scan_path):
			return true
	return false


func _get_scan_paths() -> PackedStringArray:
	var paths: PackedStringArray = []

	var extra := PopochiuConfig.get_translation_extra_scan_paths()
	if not extra.is_empty():
		for p in extra:
			var trimmed := p.strip_edges()
			if not PopochiuEditorHelper._is_valid_godot_path(trimmed):
				PopochiuUtils.print_warning("%s is not a valid path!" % p)
				continue
			if not trimmed.is_empty() and trimmed not in paths:
				paths.append(trimmed)

	return paths


func _get_function_names() -> PackedStringArray:
	var names := PackedStringArray(DEFAULT_FUNCTION_NAMES)

	var extra := PopochiuConfig.get_translation_extra_function_names()
	if not extra.is_empty():
		for n in extra.split(",", false):
			var trimmed := n.strip_edges()
			if not trimmed.is_empty() and trimmed not in names:
				names.append(trimmed)

	return names


func _compile_regexes() -> void:
	var fn_names := _get_function_names()
	var fn_group := "|".join(fn_names)

	# Matches: function_name( "string literal" ) or function_name( 'string literal' )
	# Captures the string content (group 1 for double quotes, group 2 for single quotes)
	_function_regex = RegEx.new()
	_function_regex.compile(
		"(?<!\\w)(?:%s)\\s*\\(\\s*(?:\"((?:[^\"\\\\]|\\\\.)*)\"|\\'((?:[^\\'\\\\]|\\\\.)*)\\')" % fn_group
	)

	# Matches: function_name( followed by something that is NOT a string literal
	# (variable, expression, concatenation, etc.)
	_non_literal_regex = RegEx.new()
	_non_literal_regex.compile(
		"(?<!\\w)(?:%s)\\s*\\(\\s*(?![\"\\'])[^\\)]*\\)" % fn_group
	)

	# Matches: .text = "string" or .text = 'string' (dialog option text assignment)
	_text_assignment_regex = RegEx.new()
	_text_assignment_regex.compile(
		"\\.text\\s*=\\s*(?:\"((?:[^\"\\\\]|\\\\.)*)\"|\\'((?:[^\\'\\\\]|\\\\.)*)\\')"
	)


func _extract_strings_from_file(path: String) -> Array[PackedStringArray]:
	var result: Array[PackedStringArray] = []

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return result

	var lines := file.get_as_text().split("\n")
	file.close()

	for i in range(lines.size()):
		var line := lines[i]
		var line_stripped := line.strip_edges()

		# Skip comment-only and empty lines — they are checked backwards from extraction points
		if line_stripped.is_empty() or line_stripped.begins_with("#"):
			continue

		# --- Try to extract function call string ---
		var fn_match := _function_regex.search(line)
		if fn_match:
			# Check if the matched string is part of a concatenation (e.g. "Hello" + "World")
			var after_match := line.substr(fn_match.get_end()).strip_edges()
			if after_match.begins_with("+"):
				# Treat as non-literal: warn unless suppressed
				var comment_result := _parse_comment(lines, i)
				if not comment_result.skip:
					print(
						"[Popochiu i18n] Warning: Cannot extract concatenated string at "
						+ "%s:%d — \"%s\". " % [path, i + 1, line_stripped.substr(0, 120)]
						+ "Use a direct string literal as the first argument."
					)
				continue

			var comment_result := _parse_comment(lines, i)
			if comment_result.skip:
				continue

			var extracted_string := fn_match.get_string(1)
			if extracted_string.is_empty():
				extracted_string = fn_match.get_string(2)

			if not extracted_string.is_empty():
				extracted_string = extracted_string.c_unescape()
				result.append(PackedStringArray([
					extracted_string, "", "", comment_result.comment, str(i + 1)
				]))
			continue

		# --- Detect non-literal arguments and warn ---
		var non_literal_match := _non_literal_regex.search(line)
		if non_literal_match:
			var comment_result := _parse_comment(lines, i)
			if not comment_result.skip:
				print(
					"[Popochiu i18n] Warning: Cannot extract non-literal string at "
					+ "%s:%d — \"%s\". " % [path, i + 1, line_stripped.substr(0, 120)]
					+ "Use a direct string literal as the first argument."
				)
			continue

		# --- Extract .text = "..." assignments ---
		var text_match := _text_assignment_regex.search(line)
		if text_match:
			var comment_result := _parse_comment(lines, i)
			if comment_result.skip:
				continue

			var extracted_string := text_match.get_string(1)
			if extracted_string.is_empty():
				extracted_string = text_match.get_string(2)

			if not extracted_string.is_empty():
				extracted_string = extracted_string.c_unescape()
				result.append(PackedStringArray([
					extracted_string, "", "", comment_result.comment, str(i + 1)
				]))
			continue

	return result


## Parses comments for a given line, mimicking Godot's native behavior:
## 1. Checks for an inline comment on the same line (after code)
## 2. Walks backwards through consecutive comment lines (empty lines break the chain)
## Returns a Dictionary with { skip: bool, comment: String }
func _parse_comment(lines: PackedStringArray, line_idx: int) -> Dictionary:
	var ret := { "skip": false, "comment": "" }

	# 1. Check inline comment on the same line
	var inline_comment := _get_inline_comment(lines[line_idx])
	if not inline_comment.is_empty():
		if inline_comment.begins_with("TRANSLATORS:"):
			ret.comment = inline_comment.trim_prefix("TRANSLATORS:").strip_edges()
			return ret
		if inline_comment == "NO_TRANSLATE" or inline_comment.begins_with("NO_TRANSLATE:"):
			ret.skip = true
			return ret

	# 2. Walk backwards through preceding consecutive comment lines
	var multiline_comment := ""
	var line := line_idx - 1
	while line >= 0:
		var prev_stripped := lines[line].strip_edges()
		# Non-comment line (including empty lines) breaks the chain
		if not prev_stripped.begins_with("#"):
			break

		var content := prev_stripped.trim_prefix("#").strip_edges()

		# Empty comment lines are allowed within the block (don't break the chain)
		if content.is_empty():
			line -= 1
			continue

		if multiline_comment.is_empty():
			multiline_comment = content
		else:
			multiline_comment = content + "\n" + multiline_comment

		if content.begins_with("TRANSLATORS:"):
			ret.comment = multiline_comment.trim_prefix("TRANSLATORS:").strip_edges()
			return ret

		if content == "NO_TRANSLATE" or content.begins_with("NO_TRANSLATE:"):
			ret.skip = true
			return ret

		line -= 1

	return ret


## Extracts the comment portion from a line that contains code + inline comment.
## Returns the stripped comment text (without the #), or empty string if no inline comment.
func _get_inline_comment(line: String) -> String:
	var in_double_quote := false
	var in_single_quote := false
	var prev_char := ""

	for idx in range(line.length()):
		var ch := line[idx]

		if ch == '"' and not in_single_quote and prev_char != "\\":
			in_double_quote = not in_double_quote
		elif ch == "'" and not in_double_quote and prev_char != "\\":
			in_single_quote = not in_single_quote
		elif ch == "#" and not in_double_quote and not in_single_quote:
			return line.substr(idx + 1).strip_edges()

		prev_char = ch

	return ""


#endregion
