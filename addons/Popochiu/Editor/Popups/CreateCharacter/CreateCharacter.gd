tool
extends 'res://addons/Popochiu/Editor/Popups/CreationPopup.gd'
# Allows to create a new PopochiuCharacter with the files required for its
# operation within Popochiu and to store its state:
#   Character???.tsn, Character???.gd, Character???.tres and Character???State.gd
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

const CHARACTER_STATE_TEMPLATE :=\
'res://addons/Popochiu/Engine/Templates/CharacterStateTemplate.gd'
const CHARACTER_SCRIPT_TEMPLATE :=\
'res://addons/Popochiu/Engine/Templates/CharacterTemplate.gd'
const CHARACTER_SCENE :=\
'res://addons/Popochiu/Engine/Objects/Character/PopochiuCharacter.tscn'
const Constants := preload('res://addons/Popochiu/PopochiuResources.gd')

var _new_character_name := ''
var _new_character_path := ''
var _character_path_template: String


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	_clear_fields()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func set_main_dock(node: PopochiuDock) -> void:
	.set_main_dock(node)
	# res://popochiu/Characters
	_character_path_template = _main_dock.CHARACTERS_PATH + '%s/Character%s'


func create() -> void:
	if not _new_character_name:
		_error_feedback.show()
		return
	
	# TODO: Check that there is not a character in the same PATH.
	# TODO: Delete created files if creation is not complete.
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the folder for the character
	_main_dock.dir.make_dir(_main_dock.CHARACTERS_PATH + _new_character_name)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the state Resource for the character and a script so devs
	# can add extra properties to that state
	var state_template: Script = load(CHARACTER_STATE_TEMPLATE)
	if ResourceSaver.save(_new_character_path + 'State.gd', state_template) != OK:
		push_error('[Popochiu] Could not create character state script: %s' %\
		_new_character_name)
		# TODO: Show feedback in the popup
		return
	
	var character_resource: PopochiuCharacterData =\
	load(_new_character_path + 'State.gd').new()
	character_resource.script_name = _new_character_name
	character_resource.scene = _new_character_path + '.tscn'
	character_resource.resource_name = _new_character_name
	
	if ResourceSaver.save(_new_character_path + '.tres',\
	character_resource) != OK:
		push_error('[Popochiu] Could not create PopochiuCharacterData for character: %s' %\
		_new_character_name)
		# TODO: Show feedback in the popup
		return

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the script for the character
	var character_template := load(CHARACTER_SCRIPT_TEMPLATE)
	if ResourceSaver.save(_new_character_path + '.gd', character_template) != OK:
		push_error('[Popochiu] Could not create script: %s.gd' % _new_character_name)
		# TODO: Show feedback in the popup
		return
	
	# Assign the state to the character
	var character_script: Script = load(_new_character_path + '.gd')
	character_script.source_code = character_script.source_code.replace(
		'PopochiuCharacterData = null',
		"PopochiuCharacterData = preload('Character%s.tres')" % _new_character_name
	)
	ResourceSaver.save(_new_character_path + '.gd', character_script)

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the character instance
	var new_character: PopochiuCharacter = preload(CHARACTER_SCENE).instance()
	# 	The script is assigned first so that other properties will not be
	# 	overwritten by that assignment.
	new_character.set_script(load(_new_character_path + '.gd'))
	new_character.script_name = _new_character_name
	new_character.name = 'Character' + _new_character_name
	new_character.description = _new_character_name
	new_character.cursor = Constants.CURSOR_TYPE.TALK
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Save the character scene (.tscn)
	var new_character_packed_scene: PackedScene = PackedScene.new()
	new_character_packed_scene.pack(new_character)
	if ResourceSaver.save(_new_character_path + '.tscn',\
	new_character_packed_scene) != OK:
		push_error('[Popochiu] Could not create character: %s.tscn' % _new_character_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Add the created character to Popochiu's characters list
	if _main_dock.add_resource_to_popochiu(
		'characters', ResourceLoader.load(_new_character_path + '.tres')
	) != OK:
		push_error('[Popochiu] Could not add the created character to Popochiu: %s' %\
		_new_character_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Update the list of characters in the dock
	_main_dock.add_to_list(Constants.Types.CHARACTER, _new_character_name)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Open the scene in the editor
	yield(get_tree().create_timer(0.1), 'timeout')
	_main_dock.ei.select_file(_new_character_path + '.tscn')
	_main_dock.ei.open_scene_from_path(_new_character_path + '.tscn')
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# That's all!!!
	hide()

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_name(new_text: String) -> void:
	._update_name(new_text)

	if _name:
		_new_character_name = _name
		_new_character_path = _character_path_template %\
		[_new_character_name, _new_character_name]

		_info.bbcode_text = (
			'In [b]%s[/b] the following files will be created:\n[code]%s, %s and %s[/code]' \
			% [
				_main_dock.CHARACTERS_PATH + _new_character_name,
				'Character' + _new_character_name + '.tscn',
				'Character' + _new_character_name + '.gd',
				'Character' + _new_character_name + '.tres'
			]
		)
	else:
		_info.clear()


func _clear_fields() -> void:
	._clear_fields()
	
	_new_character_name = ''
	_new_character_path = ''
