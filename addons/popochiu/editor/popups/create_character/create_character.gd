# Creates a new PopochiuCharacter.
#
# It creates all the necessary files to make a PopochiuCharacter to work and to
# store its state:
# - CharacterXXX.tsn
# - CharacterXXX.gd
# - CharacterXXX.tres
# - CharacterXXXState.gd
@tool
extends 'res://addons/popochiu/editor/popups/creation_popup.gd'

const CHARACTER_STATE_TEMPLATE :=\
'res://addons/popochiu/engine/templates/character_state_template.gd'
const CHARACTER_SCRIPT_TEMPLATE :=\
'res://addons/popochiu/engine/templates/character_template.gd'
const CHARACTER_SCENE :=\
'res://addons/popochiu/engine/objects/character/popochiu_character.tscn'
const Constants := preload('res://addons/popochiu/popochiu_resources.gd')
const PopochiuDock :=\
preload('res://addons/popochiu/editor/main_dock/popochiu_dock.gd')

var _new_character_name := ''
var _new_character_path := ''
var _character_path_template := ''
var _pascal_name := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	super()
	_clear_fields()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _create() -> void:
	if _new_character_name.is_empty():
		_error_feedback.show()
		return
	
	# TODO: Check that there is not a character in the same PATH.
	# TODO: Delete created files if creation is not complete.
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the folder for the character
	DirAccess.make_dir_absolute(
		(_main_dock as PopochiuDock).CHARACTERS_PATH + _new_character_name
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the state Resource for the character and a script so devs
	# can add extra properties to that state
	var state_template: Script = load(CHARACTER_STATE_TEMPLATE)
	if ResourceSaver.save(
		state_template, _new_character_path + '_state.gd'
	) != OK:
		push_error('[Popochiu] Could not create character state script: %s' %\
		_new_character_name)
		# TODO: Show feedback in the popup
		return
	
	var character_resource: PopochiuCharacterData =\
	load(_new_character_path + '_state.gd').new()
	character_resource.script_name = _pascal_name
	character_resource.scene = _new_character_path + '.tscn'
	character_resource.resource_name = _pascal_name
	
	if ResourceSaver.save(
		character_resource, _new_character_path + '.tres'
	) != OK:
		push_error(
			"[Popochiu] Couldn't create PopochiuCharacterData for: %s" %\
			_new_character_name
		)
		# TODO: Show feedback in the popup
		return

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the script for the character
	var character_script: Script = load(CHARACTER_SCRIPT_TEMPLATE)
	var new_code := character_script.source_code
	
	character_script.source_code = ''
	
	if ResourceSaver.save(character_script, _new_character_path + '.gd') != OK:
		push_error(
			'[Popochiu] Could not create script: %s.gd' % _new_character_name
		)
		# TODO: Show feedback in the popup
		return
	
	new_code = new_code.replace(
		'character_state_template',
		'character_%s_state' % _new_character_name
	)
	
	new_code = new_code.replace(
		'Data = null',
		"Data = load('%s.tres')" % _new_character_path
	)
	
	character_script = load(_new_character_path + '.gd')
	character_script.source_code = new_code
	
	if ResourceSaver.save(character_script, _new_character_path + '.gd') != OK:
		push_error(
			'[Popochiu] Could not update script: %s.gd' % _new_character_name
		)
		# TODO: Show feedback in the popup
		return

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the Character instance
	var new_character: PopochiuCharacter = preload(CHARACTER_SCENE).instantiate()
	# 	The script is assigned first so that other properties will not be
	# 	overwritten by that assignment.
	new_character.set_script(load(_new_character_path + '.gd'))
	
	new_character.name = 'Character' + _pascal_name
	new_character.script_name = _pascal_name
	new_character.description = _new_character_name.capitalize()
	new_character.cursor = Constants.CURSOR_TYPE.TALK
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Save the character scene (.tscn)
	var new_character_packed_scene: PackedScene = PackedScene.new()
	new_character_packed_scene.pack(new_character)
	if ResourceSaver.save(
		new_character_packed_scene, _new_character_path + '.tscn'
	) != OK:
		push_error(
			"[Popochiu] Couldn't create character: %s.tscn" % _new_character_name
		)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Add the created character to Popochiu's characters list
	if _main_dock.add_resource_to_popochiu(
		'characters', ResourceLoader.load(_new_character_path + '.tres')
	) != OK:
		push_error(
			"[Popochiu] Couldn't add the created character to Popochiu: %s" %\
			_new_character_name
		)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Add the character to the C singleton
	PopochiuResources.update_autoloads(true)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Update the list of characters in the dock
	(_main_dock as PopochiuDock).add_to_list(
		Constants.Types.CHARACTER, _pascal_name
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Open the scene in the editor
	await get_tree().create_timer(0.1).timeout
	
	_main_dock.ei.select_file(_new_character_path + '.tscn')
	_main_dock.ei.open_scene_from_path(_new_character_path + '.tscn')
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# That's all!!!
	hide()


func _clear_fields() -> void:
	_new_character_name = ''
	_new_character_path = ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func set_main_dock(node: Panel) -> void:
	super(node)
	
	if not _main_dock: return
	
	# res://popochiu/characters
	_character_path_template = _main_dock.CHARACTERS_PATH + '%s/character_%s'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_new_character_name = _name.to_snake_case()
		_pascal_name = _name
		_new_character_path = _character_path_template %\
		[_new_character_name, _new_character_name]

		_info.text = (
			'In [b]%s[/b] the following files will be created:\
			\n[code]%s, %s and %s[/code]' \
			% [
				_main_dock.CHARACTERS_PATH + _new_character_name,
				'character_' + _new_character_name + '.tscn',
				'character_' + _new_character_name + '.gd',
				'character_' + _new_character_name + '.tres'
			]
		)
		_info.show()
	else:
		_info.clear()
		_info.hide()
