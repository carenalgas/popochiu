@tool
extends 'res://addons/popochiu/editor/popups/creation_popup.gd'
## Creates a new PopochiuCharacter.
##
## It creates all the necessary files to make a PopochiuCharacter to work and to
## store its state:
## - CharacterXXX.tsn
## - CharacterXXX.gd
## - CharacterXXX.tres
## - CharacterXXXState.gd

# TODO: Giving a proper class name to PopochiuDock eliminates the need to preload it
# and to cast it as the right type later in code.
const PopochiuDock := preload('res://addons/popochiu/editor/main_dock/popochiu_dock.gd')

var _new_character_name := ''
var _factory: PopochiuCharacterFactory


#region Godot ######################################################################################
func _ready() -> void:
	super()
	_clear_fields()


#endregion

#region Virtual ####################################################################################
func _create() -> void:
	if _new_character_name.is_empty():
		_error_feedback.show()
		return
	
	# Setup the prop helper and use it to create the prop ------------------------------------------
	_factory = PopochiuCharacterFactory.new(_main_dock)

	if _factory.create(_new_character_name) != ResultCodes.SUCCESS:
		# TODO: show a message in the popup!
		return

	var character_scene = _factory.get_obj_scene()
	
	# Open the scene in the editor -----------------------------------------------------------------
	await get_tree().create_timer(0.1).timeout
	
	EditorInterface.select_file(character_scene.scene_file_path)
	EditorInterface.open_scene_from_path(character_scene.scene_file_path)
	
	hide()


func _clear_fields() -> void:
	_new_character_name = ''


#endregion

#region SetGet #####################################################################################
func set_main_dock(node: Panel) -> void:
	super(node)
	
	if not _main_dock: return


#endregion

#region Private ####################################################################################
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_new_character_name = _name.to_snake_case()

		_info.text = (
			'In [b]%s[/b] the following files will be created:\
			\n[code]- %s\n- %s\n- %s[/code]' \
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
	
	_update_size_and_position()


#endregion
