@tool
class_name PopochiuTranslationParserPlugin
extends EditorTranslationParserPlugin
# Extracts translatable strings from Popochiu game scripts by scanning for known function calls
# (say, show_system_text, etc.), native translation functions (tr, atr, tr_n, atr_n), and dialog
# option text assignments.
# This plugin overrides Godot's native GDScript parser for .gd files, so it must also handle the
# extraction of native translation function calls.

const DEFAULT_FUNCTION_NAMES: PackedStringArray = [
	"say",
	"queue_say",
	"show_system_text",
	"queue_show_system_text",
	"show_hover_text",
]

# Native Godot translation functions with a single translatable string argument
const DEFAULT_NATIVE_FUNCTION_NAMES: PackedStringArray = [
	"tr",
	"atr",
]

# Native Godot plural translation functions with two translatable string arguments
# (msgid and msgid_plural)
const DEFAULT_NATIVE_PLURAL_FUNCTION_NAMES: PackedStringArray = [
	"tr_n",
	"atr_n",
]

var _function_regex: RegEx
var _non_literal_regex: RegEx
var _native_function_regex: RegEx
var _native_non_literal_regex: RegEx
var _plural_function_regex: RegEx
var _non_literal_plural_regex: RegEx
var _context_regex: RegEx
var _context_after_expr_regex: RegEx
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
	var paths: PackedStringArray = [PopochiuResources.GAME_PATH]

	var extra := PopochiuConfig.get_translation_extra_scan_paths()
	if not extra.is_empty():
		for p in extra:
			var trimmed := p.strip_edges()
			if not PopochiuEditorHelper._is_valid_godot_path(trimmed):
				PopochiuUtils.print_warning(
					"[Popochiu i18n] Warning: \"%s\" is not a valid scan path!" % p
				)
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


func _get_native_function_names() -> PackedStringArray:
	return PackedStringArray(DEFAULT_NATIVE_FUNCTION_NAMES)


func _get_plural_function_names() -> PackedStringArray:
	var names := PackedStringArray(DEFAULT_NATIVE_PLURAL_FUNCTION_NAMES)

	var extra := PopochiuConfig.get_translation_extra_plural_function_names()
	if not extra.is_empty():
		for n in extra.split(",", false):
			var trimmed := n.strip_edges()
			if not trimmed.is_empty() and trimmed not in names:
				names.append(trimmed)

	return names


func _compile_regexes() -> void:
	var fn_group := "|".join(_get_function_names())

	# Popochiu functions: captures the first string argument (no context support)
	# Groups 1/2 = msgid (double/single quoted)
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

	# Native singular functions (tr, atr): captures the first string argument
	# Groups 1/2 = msgid (double/single quoted)
	var native_group := "|".join(_get_native_function_names())

	_native_function_regex = RegEx.new()
	_native_function_regex.compile(
		"(?<!\\w)(?:%s)\\s*\\(\\s*(?:\"((?:[^\"\\\\]|\\\\.)*)\"|\\'((?:[^\\'\\\\]|\\\\.)*)\\')" % native_group
	)

	_native_non_literal_regex = RegEx.new()
	_native_non_literal_regex.compile(
		"(?<!\\w)(?:%s)\\s*\\(\\s*(?![\"\\'])[^\\)]*\\)" % native_group
	)

	# Plural functions (tr_n, atr_n): captures two string arguments
	# Groups 1/2 = msgid (double/single quoted), groups 3/4 = msgid_plural (double/single quoted)
	var pl_group := "|".join(_get_plural_function_names())

	_plural_function_regex = RegEx.new()
	_plural_function_regex.compile(
		"(?<!\\w)(?:%s)\\s*\\(\\s*(?:\"((?:[^\"\\\\]|\\\\.)*)\"|\\'((?:[^\\'\\\\]|\\\\.)*)\\')"
		% pl_group
		+ "\\s*,\\s*(?:\"((?:[^\"\\\\]|\\\\.)*)\"|\\'((?:[^\\'\\\\]|\\\\.)*)\\')"
	)

	# Matches: plural_function_name( followed by something that is NOT a string literal
	_non_literal_plural_regex = RegEx.new()
	_non_literal_plural_regex.compile(
		"(?<!\\w)(?:%s)\\s*\\(\\s*(?![\"\\'])[^\\)]*\\)" % pl_group
	)

	# Context extraction from the remainder of the line after the main match.
	# Used for native singular: tr("msg", "ctx"). Remainder starts with `, "ctx"`.
	# Groups 1/2 = context (double/single quoted)
	_context_regex = RegEx.new()
	_context_regex.compile(
		"^\\s*,\\s*(?:\"((?:[^\"\\\\]|\\\\.)*)\"|\\'((?:[^\\'\\\\]|\\\\.)*)\\')"
	)

	# Used for native plural: tr_n("msg", "plural", n, "ctx"). Remainder starts with `, n, "ctx"`.
	# Skips one arbitrary expression (the `n` argument) then captures the context string.
	# Groups 1/2 = context (double/single quoted)
	_context_after_expr_regex = RegEx.new()
	_context_after_expr_regex.compile(
		"^\\s*,\\s*[^,]+,\\s*(?:\"((?:[^\"\\\\]|\\\\.)*)\"|\\'((?:[^\\'\\\\]|\\\\.)*)\\')"
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

		# --- Plural function calls (tr_n, atr_n, etc.): two string arguments + optional context ---
		var pl_match := _plural_function_regex.search(line)
		if pl_match:
			var comment_result := _parse_comment(lines, i)
			if comment_result.skip:
				continue

			var msgid := _get_match_string(pl_match, 1, 2)
			var msgid_plural := _get_match_string(pl_match, 3, 4)
			if not msgid.is_empty() and not msgid_plural.is_empty():
				var remainder := line.substr(pl_match.get_end())
				var msgctx := _extract_context(remainder, _context_after_expr_regex)
				result.append(PackedStringArray([
					msgid, msgctx, msgid_plural, comment_result.comment, str(i + 1)
				]))
			continue

		if _search_and_warn_non_literal(lines, i, path, line_stripped,
				_non_literal_plural_regex, "Use direct string literals as the first two arguments."):
			continue

		# --- Native singular function calls (tr, atr): one string argument + optional context ---
		var native_match := _native_function_regex.search(line)
		if native_match:
			var after_match := line.substr(native_match.get_end()).strip_edges()
			if after_match.begins_with("+"):
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

			var s := _get_match_string(native_match, 1, 2)
			if not s.is_empty():
				var remainder := line.substr(native_match.get_end())
				var msgctx := _extract_context(remainder, _context_regex)
				result.append(PackedStringArray([
					s, msgctx, "", comment_result.comment, str(i + 1)
				]))
			continue

		if _search_and_warn_non_literal(lines, i, path, line_stripped,
				_native_non_literal_regex, "Use a direct string literal as the first argument."):
			continue

		# --- Single-param function calls (say, show_system_text, etc.) ---
		var fn_match := _function_regex.search(line)
		if fn_match:
			var after_match := line.substr(fn_match.get_end()).strip_edges()
			if after_match.begins_with("+"):
				# Concatenated string ("string" + "string"): warn unless suppressed
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

			var s := _get_match_string(fn_match, 1, 2)
			if not s.is_empty():
				result.append(PackedStringArray([
					s, "", "", comment_result.comment, str(i + 1)
				]))
			continue

		if _search_and_warn_non_literal(lines, i, path, line_stripped,
				_non_literal_regex, "Use a direct string literal as the first argument."):
			continue

		# --- Dialog option text assignments (.text = "...") ---
		var text_match := _text_assignment_regex.search(line)
		if text_match:
			var comment_result := _parse_comment(lines, i)
			if comment_result.skip:
				continue

			var s := _get_match_string(text_match, 1, 2)
			if not s.is_empty():
				result.append(PackedStringArray([
					s, "", "", comment_result.comment, str(i + 1)
				]))
			continue

	return result


# Returns the first non-empty captured string from two alternative capture groups (double/single
# quoted), decoded from GDScript escape sequences. Returns empty string if both groups are empty.
func _get_match_string(m: RegExMatch, group_double: int, group_single: int) -> String:
	var s := m.get_string(group_double)
	if s.is_empty():
		s = m.get_string(group_single)
	if s.is_empty():
		return ""
	return s.c_unescape()


# Extracts an optional context string from the remainder of the line after the main match.
# The `context_regex` determines the expected pattern (direct context or context after an
# expression). Returns empty string if no context is found.
func _extract_context(remainder: String, context_regex: RegEx) -> String:
	var ctx_match := context_regex.search(remainder)
	if not ctx_match:
		return ""
	return _get_match_string(ctx_match, 1, 2)


# Searches a regex on the given line; if it matches, prints a non-literal warning unless
# suppressed by NO_TRANSLATE. Returns true when matched so the caller can skip further
# processing with `continue`.
func _search_and_warn_non_literal(
	lines: PackedStringArray,
	line_idx: int,
	path: String,
	line_stripped: String,
	regex: RegEx,
	fix_hint: String,
) -> bool:
	if not regex.search(lines[line_idx]):
		return false
	var comment_result := _parse_comment(lines, line_idx)
	if not comment_result.skip:
		print(
			"[Popochiu i18n] Warning: Cannot extract non-literal string at "
			+ "%s:%d — \"%s\". " % [path, line_idx + 1, line_stripped.substr(0, 120)]
			+ fix_hint
		)
	return true


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
