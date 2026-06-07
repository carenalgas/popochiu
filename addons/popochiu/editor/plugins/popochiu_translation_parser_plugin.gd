@tool
class_name PopochiuTranslationParserPlugin
extends EditorTranslationParserPlugin
# Extracts translatable strings from Popochiu game scripts by scanning for known function calls
# (say, show_system_text, etc.), native translation functions (tr, atr, tr_n, atr_n), and dialog
# option text assignments.
# This plugin overrides Godot's native GDScript parser for .gd files, so it must also handle the
# extraction of native translation function calls.

const DEFAULT_POPOCHIU_FUNCTION_NAMES: PackedStringArray = [
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

# Popochiu has no built-in plural functions; this stub is reserved for future implementations
const DEFAULT_POPOCHIU_PLURAL_FUNCTION_NAMES: PackedStringArray = []

# Cached on first use; valid for the lifetime of the plugin instance
var _scan_paths: PackedStringArray
var _is_initialized: bool = false

# Compiled regular expressions for parsing; cached on first use.
var _singular_function_regex: RegEx
var _singular_non_literal_regex: RegEx
var _plural_function_regex: RegEx
var _plural_non_literal_regex: RegEx
var _context_regex: RegEx
var _context_after_expr_regex: RegEx
var _text_assignment_regex: RegEx
var _function_def_regex: RegEx
var _multiline_start_regex: RegEx
var _dq_string_regex: RegEx
var _sq_string_regex: RegEx

# Tokenizer for triple-quoted string normalization.
var _triple_quote_tokenizer: RegEx

# Parse state. Ephemeral, only valid during a call to _extract_strings_from_file()
# Per-file
var _parse_path: String
var _parse_current_function: String
var _parse_lines: PackedStringArray
var _parse_result: Array[PackedStringArray]
# Per-iteration
var _parse_idx: int
var _parse_line: String
var _parse_line_stripped: String
# Pending modifier (survives across lines until consumed or discarded)
var _parse_pending_skip: bool
var _parse_pending_comment: String
var _parse_in_translators_block: bool
var _parse_pending_modifier_line: int
# Per-code-line snapshot (set when a code line is reached)
var _parse_line_skip: bool
var _parse_line_comment: String


#region Godot ######################################################################################
func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["gd", "tres"])


func _parse_file(path: String) -> Array[PackedStringArray]:
	# EditorTranslationParserPlugin extends RefCounted, so there is no _ready() or scene-tree
	# lifecycle to hook into. Using a constructor (_init) would run too early, before PopochiuConfig
	# and PopochiuResources are guaranteed to be available. Lazy initialization on the first
	# _parse_file() call is therefore the safest point, at the cost of a ugly semaphore variable.
	if not _is_initialized:
		_initialize()

	if not _is_in_scan_paths(path):
		return []

	if path.get_extension() == "tres":
		return _extract_strings_from_resource(path)
	return _extract_strings_from_script(path)


#endregion

#region Godot 4.7: uncomment when _customize_strings() becomes available ########################
# Called after all files have been parsed. Scans target paths and appends extracted strings.
#	func _customize_strings(strings: Array[PackedStringArray]) -> Array[PackedStringArray]:
#		_compile_regexes()
#
#		var scan_paths := _get_scan_paths()
#		for scan_path in scan_paths:
#			var files := _get_gd_files_in_path(scan_path)
#			for file_path in files:
#				var extracted := _extract_strings_from_script(file_path)
#				strings.append_array(extracted)
#
#		return strings
#
#
#	func _get_gd_files_in_path(path: String) -> PackedStringArray:
#		var files: PackedStringArray = []
#		var dir := DirAccess.open(path)
#		if not dir:
#			return files
#
#		dir.list_dir_begin()
#		var file_name := dir.get_next()
#		while file_name != "":
#			var full_path := path.path_join(file_name)
#			if dir.current_is_dir():
#				files.append_array(_get_gd_files_in_path(full_path))
#			elif file_name.get_extension() == "gd":
#				files.append(full_path)
#			file_name = dir.get_next()
#		dir.list_dir_end()
#
#		return files
#endregion

#region Private ####################################################################################
func _initialize() -> void:
	_scan_paths = _get_scan_paths()
	_compile_regexes()
	_is_initialized = true


func _is_in_scan_paths(path: String) -> bool:
	for scan_path in _scan_paths:
		if path.begins_with(scan_path):
			return true
	return false


func _get_scan_paths() -> PackedStringArray:
	var paths: PackedStringArray = [PopochiuResources.GAME_PATH]

	var extra := PopochiuConfig.get_translation_extra_scan_paths()
	if not extra.is_empty():
		for p in extra:
			var trimmed := p.strip_edges()
			if not PopochiuEditorHelper.is_valid_godot_path(trimmed):
				PopochiuUtils.print_warning(
					"[i18n] \"%s\" is not a valid scan path!" % p
				)
				continue
			if not trimmed.is_empty() and trimmed not in paths:
				paths.append(trimmed)

	return paths


func _get_singular_function_names() -> PackedStringArray:
	# Merge Popochiu defaults + native singular defaults into one set
	var names := PackedStringArray()
	names.append_array(DEFAULT_POPOCHIU_FUNCTION_NAMES)
	names.append_array(DEFAULT_NATIVE_FUNCTION_NAMES)
	_append_extra_names(names, PopochiuConfig.get_translation_extra_function_names())
	return names


func _get_plural_function_names() -> PackedStringArray:
	# Merge Popochiu plural defaults (currently empty) + native plural defaults
	var names := PackedStringArray()
	names.append_array(DEFAULT_POPOCHIU_PLURAL_FUNCTION_NAMES)
	names.append_array(DEFAULT_NATIVE_PLURAL_FUNCTION_NAMES)
	_append_extra_names(names, PopochiuConfig.get_translation_extra_plural_function_names())
	return names


func _append_extra_names(names: PackedStringArray, extra: String) -> void:
	if extra.is_empty():
		return
	for n in extra.split(",", false):
		var trimmed := n.strip_edges()
		if not PopochiuEditorHelper.is_valid_function_name(trimmed):
			PopochiuUtils.print_warning(
				"[i18n] Remove \"%s\" entry from Extra (Plural) Function Names in Project Settings."
				% trimmed
			)
			continue
		if not trimmed.is_empty() and trimmed not in names:
			names.append(trimmed)
	# No need to return, `names` is passed by reference.


func _compile_regexes() -> void:
	# Singular functions: Popochiu defaults + native singular + user extra.
	# Group 1 = matched function name (used to decide whether context must be extracted).
	# Groups 2/3 = msgid (double/single quoted).
	var singular_group := "|".join(_get_singular_function_names())

	_singular_function_regex = RegEx.new()
	_singular_function_regex.compile(
		"(?<!\\w)((?:%s))\\s*\\(\\s*(?:\"((?:[^\"\\\\]|\\\\.)*)\"|\\'((?:[^\\'\\\\]|\\\\.)*)\\')"
		% singular_group
	)

	_singular_non_literal_regex = RegEx.new()
	_singular_non_literal_regex.compile(
		"(?<!\\w)(?:%s)\\s*\\(\\s*(?![\"\\'])[^\\)]*\\)" % singular_group
	)

	# Plural functions: Popochiu plural defaults (empty) + native plural + user extra.
	# Group 1 = matched function name (used to decide whether context must be extracted).
	# Groups 2/3 = msgid (double/single quoted), groups 4/5 = msgid_plural (double/single quoted).
	var pl_group := "|".join(_get_plural_function_names())

	_plural_function_regex = RegEx.new()
	_plural_function_regex.compile(
		"(?<!\\w)((?:%s))\\s*\\(\\s*(?:\"((?:[^\"\\\\]|\\\\.)*)\"|\\'((?:[^\\'\\\\]|\\\\.)*)\\')"
		% pl_group + "\\s*,\\s*(?:\"((?:[^\"\\\\]|\\\\.)*)\"|\\'((?:[^\\'\\\\]|\\\\.)*)\\')"
	)

	_plural_non_literal_regex = RegEx.new()
	_plural_non_literal_regex.compile(
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

	# Matches .text = "string" or text = "string" (without the leading dot, as in create_option()
	# dict keys) to cover both property-style and dictionary-style text assignments.
	_text_assignment_regex = RegEx.new()
	_text_assignment_regex.compile(
		"(?<!\\w)\\.?text\\s*=\\s*(?:\"((?:[^\"\\\\]|\\\\.)*)\"|\\'((?:[^\\'\\\\]|\\\\.)*)\\')"
	)

	_function_def_regex = RegEx.new()
	_function_def_regex.compile(
		"^(?:static\\s+)?func\\s+([a-zA-Z_]\\w*)\\s*\\("
	)

	# Multi-line call start detection: any recognized function name followed by (
	# with unbalanced parens on the line.
	var multiline_names := PackedStringArray()
	multiline_names.append_array(_get_singular_function_names())
	multiline_names.append_array(_get_plural_function_names())
	var multiline_group := "|".join(multiline_names)
	_multiline_start_regex = RegEx.new()
	_multiline_start_regex.compile("(?<!\\w)(?:%s)\\s*\\(" % multiline_group)

	_dq_string_regex = RegEx.new()
	_dq_string_regex.compile('"(?:[^"\\\\]|\\\\.)*"')
	_sq_string_regex = RegEx.new()
	_sq_string_regex.compile("'(?:[^'\\\\]|\\\\.)*'")

	# Tokenizer for triple-quoted string normalization.
	# Alternatives are evaluated left-to-right; regular strings and comments must match
	# before triple quotes so that """ inside a string or comment is not misinterpreted.
	_triple_quote_tokenizer = RegEx.new()
	_triple_quote_tokenizer.compile(
		"(" +
		# 1. Regular double-quoted string (refuse empty "" when it would start """)
		'""(?!\")|"(?:[^"\\\\]|\\\\.)+"' +
		"|" +
		# 2. Regular single-quoted string (refuse empty '' when it would start ''')
		"''(?!')|'(?:[^'\\\\]|\\\\.)+'" +
		"|" +
		# 3. Line comment
		"#[^\\n]*" +
		"|" +
		# 4. Triple-double-quoted string
		"\"\"\"[\\s\\S]*?\"\"\"" +
		"|" +
		# 5. Triple-single-quoted string
		"'''[\\s\\S]*?'''" +
		"|" +
		# 6. Fast path: long runs of safe characters (stop before # so comments are detected)
		"[^\"'\\n#]+" +
		"|" +
		# 7. Any single character (fallback)
		"[\\s\\S]" +
		")"
	)


func _extract_strings_from_script(path: String) -> Array[PackedStringArray]:
	_parse_path = path
	_parse_result = []
	_parse_pending_skip = false
	_parse_pending_comment = ""
	_parse_in_translators_block = false
	_parse_pending_modifier_line = 0
	_parse_current_function = ""

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return _parse_result
	var source := file.get_as_text()
	file.close()

	# ---- Step 1: Normalize triple-quoted strings ("""...""" and '''...''') ----
	var norm := _normalize_triple_quotes(source)

	# ---- Step 2: Collapse multiline function calls with single-line strings ----
	norm = _collapse_fn_calls(norm.text, norm.line_map)

	# ---- Step 3: Split normalized text into lines and run extraction ----
	_parse_lines = norm.text.split("\n")
	var line_map: PackedInt32Array = norm.line_map

	for i in range(_parse_lines.size()):
		_parse_idx = line_map[i] if i < line_map.size() else i
		_parse_line = _parse_lines[i]
		_parse_line_stripped = _parse_line.strip_edges()

		if _parse_line_stripped.is_empty():
			_handle_empty_line()
			continue

		if _parse_line_stripped.begins_with("#"):
			_handle_comment_line()
			continue

		_snapshot_and_reset_pending()
		_apply_inline_modifiers()

		# Track the current function name for forged context
		var func_def := _function_def_regex.search(_parse_line_stripped)
		if func_def:
			_parse_current_function = func_def.get_string(1)

		# Single path for all match types
		var matched := (
			_try_plural_match()
			or _try_singular_match()
			or _try_text_assignment()
		)
		if not matched:
			_check_unused_modifiers()

	_parse_lines = PackedStringArray()
	var result := _parse_result
	_parse_result = []
	return result


# Loads a PopochiuDialog .tres resource and extracts translatable strings from its options.
# Returns an empty array silently for any .tres that is not a PopochiuDialog — other .tres files
# (settings, GUI resources, etc.) may legitimately fall inside a scan path.
func _extract_strings_from_resource(path: String) -> Array[PackedStringArray]:
	var res := load(path)
	if not res or not res is PopochiuDialog:
		return []

	var result: Array[PackedStringArray] = []
	var ctx := _path_to_display_name(path)
	for opt in res.options:
		if opt is PopochiuDialogOption and not opt.text.is_empty():
			result.append(PackedStringArray([opt.text, ctx, "", "", path]))
	return result


# Handles a blank line: if a modifier was pending, it can never apply. Warn and discard.
func _handle_empty_line() -> void:
	if _parse_pending_skip or not _parse_pending_comment.is_empty():
		PopochiuUtils.print_warning(
			"[i18n] Modifier at %s:%d not applied, since followed by a blank line."
			% [_parse_path, _parse_pending_modifier_line]
		)
	_parse_pending_skip = false
	_parse_pending_comment = ""
	_parse_in_translators_block = false
	_parse_pending_modifier_line = 0


# Handles a comment-only line: updates pending modifier state without consuming it.
# A bare '#' (empty content) does not break an active TRANSLATORS block.
func _handle_comment_line() -> void:
	var content := _parse_line_stripped.trim_prefix("#").strip_edges()

	if content.is_empty():
		return

	if content.begins_with("TRANSLATORS:"):
		_parse_pending_comment = content.trim_prefix("TRANSLATORS:").strip_edges()
		_parse_pending_skip = false
		_parse_in_translators_block = true
		_parse_pending_modifier_line = _parse_idx + 1
		return

	if content == "NO_TRANSLATE" or content.begins_with("NO_TRANSLATE:"):
		_parse_pending_skip = true
		_parse_pending_comment = ""
		_parse_in_translators_block = false
		_parse_pending_modifier_line = _parse_idx + 1
		return

	if _parse_in_translators_block:
		_parse_pending_comment += "\n" + content


# Copies pending modifier state into the per-line snapshot and clears the pending state.
# Called at the start of processing any code line.
func _snapshot_and_reset_pending() -> void:
	_parse_line_skip = _parse_pending_skip
	_parse_line_comment = _parse_pending_comment
	_parse_pending_skip = false
	_parse_pending_comment = ""
	_parse_in_translators_block = false
	_parse_pending_modifier_line = 0


# Reads the inline comment from the current code line and merges it into the snapshot.
# Inline modifiers take priority over any pending modifier that was already snapshotted.
func _apply_inline_modifiers() -> void:
	var inline := _get_inline_comment(_parse_line)
	if inline.is_empty():
		return

	if inline == "NO_TRANSLATE" or inline.begins_with("NO_TRANSLATE:"):
		_parse_line_skip = true
		_parse_line_comment = ""
	elif inline.begins_with("TRANSLATORS:"):
		_parse_line_comment = inline.trim_prefix("TRANSLATORS:").strip_edges()
		_parse_line_skip = false


# Called when no match was found on a code line: if modifiers were set, they will never apply.
func _check_unused_modifiers() -> void:
	if _parse_line_skip or not _parse_line_comment.is_empty():
		PopochiuUtils.print_warning(
			"[i18n] Modifier not applied at %s:%d: "
			% [_parse_path, _parse_idx + 1]
			+ "no translatable string found on this line."
		)


# Tries to match plural function calls (tr_n, atr_n, etc.) on the current line.
# Returns true if the line was consumed (match found or non-literal warned).
func _try_plural_match() -> bool:
	var pl_match := _plural_function_regex.search(_parse_line)
	if pl_match:
		if _line_has_concatenation(pl_match):
			return true
		if not _parse_line_skip:
			var fn_name := pl_match.get_string(1)
			var msgid := _get_match_string(pl_match, 2, 3)
			var msgid_plural := _get_match_string(pl_match, 4, 5)
			if not msgid.is_empty() and not msgid_plural.is_empty():
				var msgctx := _forge_context()
				if fn_name in DEFAULT_NATIVE_PLURAL_FUNCTION_NAMES:
					var remainder := _parse_line.substr(pl_match.get_end())
					var native_ctx := _extract_context(remainder, _context_after_expr_regex)
					if not native_ctx.is_empty():
						msgctx += " - " + native_ctx
				_parse_result.append(PackedStringArray([
					msgid, msgctx, msgid_plural, _parse_line_comment, str(_parse_idx + 1)
				]))
		return true

	return _search_and_warn_non_literal(
		_plural_non_literal_regex,
		"Check the two first arguments are direct string literals."
	)


# Tries to match singular function calls on the current line. This covers Popochiu functions
# (say, show_system_text, etc.) and native Godot functions (tr, atr), as well as any user-defined
# extra functions. Native functions additionally support an optional context argument.
# Returns true if the line was consumed (match found or non-literal warned).
func _try_singular_match() -> bool:
	var fn_match := _singular_function_regex.search(_parse_line)
	if fn_match:
		if _line_has_concatenation(fn_match):
			return true
		if not _parse_line_skip:
			var fn_name := fn_match.get_string(1)
			var s := _get_match_string(fn_match, 2, 3)
			if not s.is_empty():
				var msgctx := _forge_context()
				if fn_name in DEFAULT_NATIVE_FUNCTION_NAMES:
					var remainder := _parse_line.substr(fn_match.get_end())
					var native_ctx := _extract_context(remainder, _context_regex)
					if not native_ctx.is_empty():
						msgctx += " - " + native_ctx
				_parse_result.append(PackedStringArray([
					s, msgctx, "", _parse_line_comment, str(_parse_idx + 1)
				]))
		return true

	return _search_and_warn_non_literal(
		_singular_non_literal_regex,
		"Check the first argument is a direct string literal."
	)


# Tries to match dialog option text assignments on the current line. Covers both the
# property-style (.text = "...") and the dictionary-key style (text = "...") used inside
# create_option() calls. Returns true if the line was consumed.
func _try_text_assignment() -> bool:
	var text_match := _text_assignment_regex.search(_parse_line)
	if not text_match:
		return false

	if not _parse_line_skip:
		var s := _get_match_string(text_match, 1, 2)
		if not s.is_empty():
			_parse_result.append(PackedStringArray([
				s, _forge_context(), "", _parse_line_comment, str(_parse_idx + 1)
			]))
	return true


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


# Searches a regex on the current parse line; if it matches, prints a non-literal warning unless
# suppressed by NO_TRANSLATE. Returns true when matched so the caller can propagate the skip.
func _search_and_warn_non_literal(regex: RegEx, fix_hint: String) -> bool:
	if not regex.search(_parse_line):
		return false
	if not _parse_line_skip:
		PopochiuUtils.print_warning(
			"[i18n] Cannot extract non-literal string at "
			+ "%s:%d: \"%s\". " % [_parse_path, _parse_idx + 1,
				_parse_line_stripped.substr(0, 120)]
			+ fix_hint
		)
	return true


# Checks if the remainder of the line after a match starts with a concatenation operator,
# which cannot be extracted.
func _line_has_concatenation(match: RegExMatch) -> bool:
	# Ingnore this check if the line is already marked to be skipped, to avoid duplicate warnings.
	if _parse_line_skip:
		return false

	# Check if the remainder of the line after the match starts with a
	# concatenation operator, which cannot be extracted.
	var after_match := _parse_line.substr(match.get_end()).strip_edges()
	if after_match.begins_with("+"):
		PopochiuUtils.print_warning(
			"[i18n] Cannot extract concatenated string at "
			+ "%s:%d: \"%s\". " % [_parse_path, _parse_idx + 1,
				_parse_line_stripped.substr(0, 120)]
			+ "Always use a single string literal as the first argument."
		)
		return true

	# No concatenation detected.
	return false


# Extracts the comment portion from a line that contains code + inline comment.
# Returns the stripped comment text (without the #), or empty string if no inline comment.
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


# Transforms a file path into a human-readable display name suitable for translation context.
# Strips the `popochiu_` prefix from filenames, replaces underscores with spaces, and applies
# capitalization. Examples:
#   room_kitchen.gd		 -> "Room Kitchen"
#   popochiu_globals.gd	 -> "Globals"
#   dialog_opening_dialog.tres -> "Dialog Opening Dialog"
func _path_to_display_name(path: String) -> String:
	var filename := path.get_file().get_basename()
	if filename.begins_with("popochiu_"):
		filename = filename.trim_prefix("popochiu_")
	return filename.capitalize()


# Forges a translation context string from the current script's display name and the current
# function name. If no function is being tracked, only the display name is returned.
#   Room Kitchen _on_room_entered
#   Globals do_stuff
#   Prop Trophy _on_click
func _forge_context() -> String:
	var ctx := _path_to_display_name(_parse_path)
	if not _parse_current_function.is_empty():
		ctx += " " + _parse_current_function
	return ctx


# Strips string literals and inline comments, then checks if `(` outnumbers `)`.
func _has_unbalanced_parens(text: String) -> bool:
	var s := text
	s = _dq_string_regex.sub(s, "", true)
	s = _sq_string_regex.sub(s, "", true)
	var hash_pos := s.find("#")
	if hash_pos >= 0:
		s = s.substr(0, hash_pos)
	return s.count("(") > s.count(")")


# ---- Whole-file normalization helpers for triple-quoted string support ----

# Scans the entire source text and replaces all triple-quoted strings ("""...""" and '''...''')
# with their canonical double-quoted equivalents. The raw content between delimiters is
# processed through c_unescape() + c_escape() to normalize escape sequences, and bare quotes
# inside triple-quoted strings are properly escaped for the single-line equivalent.
# Returns a Dictionary with { text: String, line_map: PackedInt32Array } where line_map[i]
# gives the 0-based original-line number for each normalized-line index i.
func _normalize_triple_quotes(source: String) -> Dictionary:
	var output := ""
	var line_map := PackedInt32Array()
	var orig_line := 0

	# First normalized line starts at original line 0
	line_map.append(0)

	for m in _triple_quote_tokenizer.search_all(source):
		var s := m.get_string()
		var start := s.substr(0, 3)

		if start == '"""' or start == "'''":
			# Triple-quoted string — collapse to a single double-quoted literal.
			# s includes the delimiters, so strip the first and last 3 characters.
			var content := s.substr(3, s.length() - 6)

			# Count newlines in the raw content for line-map tracking.
			var content_newlines := 0
			for pos in range(content.length()):
				if content[pos] == '\n':
					content_newlines += 1


			if content.is_empty():
				# Empty triple-quoted string """""" — emit "" (skipped at extraction)
				output += '""'
			else:
				# Process escapes via c_unescape, then re-escape for double-quoted format
				output += '"' + content.c_unescape().c_escape() + '"'

			orig_line += content_newlines
		elif s == "\n":
			output += s
			orig_line += 1
			line_map.append(orig_line)
		else:
			# Regular string, comment, or code — pass through unchanged
			output += s

	if line_map.is_empty():
		line_map.append(0)

	return { "text": output, "line_map": line_map }


# After triple-quote normalization, some function calls may still span multiple lines
# (e.g. tr(\n"arg1",\n"arg2"\n)). This method finds calls with unbalanced parentheses
# and collapses them to a single line, stripping whitespace within the parens.
# Returns the same Dictionary format as _normalize_triple_quotes().
func _collapse_fn_calls(text: String, line_map: PackedInt32Array) -> Dictionary:
	var lines := text.split("\n")
	var result_lines: PackedStringArray = []
	var result_map: PackedInt32Array = []
	var skip_until := -1

	for i in range(lines.size()):
		if i <= skip_until:
			continue

		var line := lines[i]
		var fn_match := _multiline_start_regex.search(line)

		# Not a multiline call? Just pass it through.
		if not fn_match or not _has_unbalanced_parens(line):
			result_lines.append(line)
			result_map.append(line_map[i] if i < line_map.size() else i)
			continue

		# It's multiline — gobble lines until balanced.
		var joined := line
		var j := i + 1
		while j < lines.size():
			var stripped := lines[j].strip_edges()
			if not stripped.is_empty() and not stripped.begins_with("#"):
				joined += stripped
			if not _has_unbalanced_parens(joined):
				break
			j += 1

		joined = _collapse_paren_ws(joined)
		result_lines.append(joined)
		result_map.append(line_map[i] if i < line_map.size() else i)
		skip_until = j

	return { "text": "\n".join(result_lines), "line_map": result_map }


# Removes newlines and collapses extraneous whitespace within function-call parentheses,
# while preserving whitespace inside string literals. Operates on a single-line or
# joined-multiline function call.
func _collapse_paren_ws(s: String) -> String:
	var open_paren := s.find("(")
	var close_paren := s.rfind(")")
	if close_paren == -1 or close_paren <= open_paren:
		return s

	var prefix := s.substr(0, open_paren + 1)
	var middle := s.substr(open_paren + 1, close_paren - open_paren - 1)
	var suffix := s.substr(close_paren)

	# Reuse the same tokenizer so strings and comments are recognized without
	# duplicating hand-rolled quote-escape tracking.
	var result := ""
	var last_was_ws := false

	for m in _triple_quote_tokenizer.search_all(middle):
		var tok := m.get_string()
		var start := tok.substr(0, 3)

		# Any string literal (regular or triple-quoted) is preserved verbatim.
		if start == '"""' or start == "'''" or tok.begins_with('"') or tok.begins_with("'"):
			result += tok
			last_was_ws = false
			continue

		# Line comments are stripped (they only appear inside the middle because
		# _collapse_fn_calls skips comment-only continuation lines, but inline
		# comments on continuation lines survive the join).
		if tok.begins_with("#"):
			last_was_ws = true
			continue

		# Collapse whitespace-only tokens (newlines, spaces, tabs) into a single
		# boundary flag.
		if tok.strip_edges().is_empty():
			last_was_ws = true
			continue

		# Code token — prepend a single space when there was whitespace before it
		# and the result does not already end with '(' (avoids "fn( arg").
		if last_was_ws and not result.is_empty() and not result.ends_with("("):
			result += " "
		result += tok
		last_was_ws = false

	# Remove spaces around commas and trim edges
	result = result.replace(" ,", ",")
	result = result.replace(", ", ",")
	result = result.strip_edges()

	return prefix + result + suffix


#endregion
