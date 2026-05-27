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
var _no_translate_regex: RegEx
var _translators_regex: RegEx


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
	var paths: PackedStringArray = [PopochiuResources.GAME_PATH]

	var extra := PopochiuConfig.get_translation_extra_scan_paths()
	if not extra.is_empty():
		for p in extra.split(",", false):
			var trimmed := p.strip_edges()
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

	# Matches: # NO_TRANSLATE or #NO_TRANSLATE (with optional leading whitespace)
	_no_translate_regex = RegEx.new()
	_no_translate_regex.compile("^\\s*#\\s*NO_TRANSLATE|#\\s*NO_TRANSLATE")

	# Matches: # TRANSLATORS: <message> or #TRANSLATORS: <message>
	_translators_regex = RegEx.new()
	_translators_regex.compile("#\\s*TRANSLATORS:\\s*(.*)")


func _extract_strings_from_file(path: String) -> Array[PackedStringArray]:
	var result: Array[PackedStringArray] = []

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return result

	var lines := file.get_as_text().split("\n")
	file.close()

	var translators_comment := ""

	for i in range(lines.size()):
		var line := lines[i]
		var line_stripped := line.strip_edges()

		# Skip fully commented-out lines (but still check for TRANSLATORS comment)
		var translators_match := _translators_regex.search(line)
		if translators_match:
			translators_comment = translators_match.get_string(1).strip_edges()
			continue

		if line_stripped.begins_with("#"):
			# Reset translators comment if this is some other comment
			if not _translators_regex.search(line):
				translators_comment = ""
			continue

		# Check for NO_TRANSLATE on this line
		if _no_translate_regex.search(line):
			translators_comment = ""
			continue

		# Check if the previous non-empty line had NO_TRANSLATE
		var prev_has_no_translate := false
		if i > 0:
			var prev_line := lines[i - 1].strip_edges()
			if _no_translate_regex.search(prev_line):
				prev_has_no_translate = true

		if prev_has_no_translate:
			translators_comment = ""
			continue

		# --- Extract function call strings ---
		var fn_match := _function_regex.search(line)
		if fn_match:
			var extracted_string := fn_match.get_string(1)
			if extracted_string.is_empty():
				extracted_string = fn_match.get_string(2)

			if not extracted_string.is_empty():
				# Unescape the string
				extracted_string = extracted_string.c_unescape()
				result.append(PackedStringArray([
					extracted_string, "", "", translators_comment, str(i + 1)
				]))

			translators_comment = ""
			continue

		# --- Detect non-literal arguments and warn ---
		var non_literal_match := _non_literal_regex.search(line)
		if non_literal_match:
			push_warning(
				"[Popochiu i18n] Cannot extract non-literal string at %s:%d — \"%s\". "
				% [path, i + 1, line_stripped.substr(0, 120)]
				+ "Use a direct string literal as the first argument."
			)
			translators_comment = ""
			continue

		# --- Extract .text = "..." assignments ---
		var text_match := _text_assignment_regex.search(line)
		if text_match:
			var extracted_string := text_match.get_string(1)
			if extracted_string.is_empty():
				extracted_string = text_match.get_string(2)

			if not extracted_string.is_empty():
				extracted_string = extracted_string.c_unescape()
				result.append(PackedStringArray([
					extracted_string, "", "", translators_comment, str(i + 1)
				]))

			translators_comment = ""
			continue

		# Reset translators comment if line doesn't match anything
		if not line_stripped.is_empty():
			translators_comment = ""

	return result


#endregion
