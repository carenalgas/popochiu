@tool
class_name PopochiuMigration15
extends PopochiuMigration

const VERSION = 15
const DESCRIPTION = "Migrate say/queue_say emotion parameter to explicit emotion property assignment"
const STEPS = [
	"Replace say(text, emotion) calls with emotion assignment pattern",
	"Replace queue_say(text, emotion) calls (strip emotion argument)",
	"Remove deprecated popochiu/dialogs/use_translations setting",
]


#region Virtual ####################################################################################
func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			_migrate_say_emotion,
			_migrate_queue_say_emotion,
			_remove_use_translations_setting,
		]
	)


#endregion

#region Private ####################################################################################
## Replaces .say(text, "emotion") and .say(text, variable) with:
##   obj.emotion = "emotion"
##   await obj.say(text)
##   obj.emotion = ""
func _migrate_say_emotion() -> Completion:
	# Pattern for say with a string literal emotion (the most common case):
	# Captures: $1=indentation, $2=await prefix, $3=object, $4=first arg, $5=emotion string
	var string_emotion_replaced := PopochiuMigrationHelper.replace_regex_in_scripts([
		{
			pattern = r'(\t*)(await\s+)?(.+?)\.say\((.+),\s*"([^"]+)"\)',
			to = "$1$3.emotion = \"$5\"\n$1$2$3.say($4)\n$1$3.emotion = \"\""
		},
	])

	# Pattern for say with a variable emotion:
	# Captures: $1=indentation, $2=await prefix, $3=object, $4=first arg, $5=variable name
	var variable_emotion_replaced := PopochiuMigrationHelper.replace_regex_in_scripts([
		{
			pattern = r"(\t*)(await\s+)?(.+?)\.say\((.+),\s+([a-zA-Z_]\w*)\s*\)",
			to = "$1$3.emotion = $5\n$1$2$3.say($4)\n$1$3.emotion = \"\""
		},
	])

	if string_emotion_replaced or variable_emotion_replaced:
		return Completion.DONE
	return Completion.IGNORED


## Strips the emotion argument from queue_say calls.
## queue_say is used inside E.queue() arrays where multi-line replacements aren't possible.
func _migrate_queue_say_emotion() -> Completion:
	# Strip string literal emotion from queue_say
	var string_replaced := PopochiuMigrationHelper.replace_regex_in_scripts([
		{
			pattern = r'(.+?)\.queue_say\((.+),\s*"[^"]+"\)',
			to = "$1.queue_say($2)"
		},
	])

	# Strip variable emotion from queue_say
	var variable_replaced := PopochiuMigrationHelper.replace_regex_in_scripts([
		{
			pattern = r"(.+?)\.queue_say\((.+),\s+[a-zA-Z_]\w*\s*\)",
			to = "$1.queue_say($2)"
		},
	])

	if string_replaced or variable_replaced:
		return Completion.DONE
	return Completion.IGNORED


## Removes the deprecated popochiu/dialogs/use_translations ProjectSettings key.
func _remove_use_translations_setting() -> Completion:
	if ProjectSettings.has_setting("popochiu/dialogs/use_translations"):
		ProjectSettings.set_setting("popochiu/dialogs/use_translations", null)
		ProjectSettings.save()
		return Completion.DONE
	return Completion.IGNORED


#endregion
