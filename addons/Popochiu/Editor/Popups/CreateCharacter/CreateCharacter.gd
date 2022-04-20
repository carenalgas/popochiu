tool
extends 'res://addons/Popochiu/Editor/Popups/CreationPopup.gd'
# Permite crear un nuevo personaje con los archivos necesarios para que funcione
# en el Popochiu: CharacterCCC.tscn, CharacterCCC.gd, CharacterCCC.tres.

const CHARACTER_SCRIPT_TEMPLATE := 'res://addons/Popochiu/Engine/Templates/CharacterTemplate.gd'
const CHARACTER_SCENE := 'res://addons/Popochiu/Engine/Objects/Character/PopochiuCharacter.tscn'
const Constants := preload('res://addons/Popochiu/Constants.gd')

var _new_character_name := ''
var _new_character_path := ''
var _character_path_template: String


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	_clear_fields()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func set_main_dock(node: PopochiuDock) -> void:
	.set_main_dock(node)
	# Por defecto: res://popochiu/Characters
	_character_path_template = _main_dock.CHARACTERS_PATH + '%s/Character%s'


func create() -> void:
	if not _new_character_name:
		_error_feedback.show()
		return
	
	# TODO: Verificar si no hay ya un personaje en el mismo PATH.
	# TODO: Eliminar archivos creados si la creación no se completa.
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el directorio donde se guardará el nuevo personaje
	_main_dock.dir.make_dir(_main_dock.CHARACTERS_PATH + _new_character_name)

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el script del nuevo personaje
	var character_template := load(CHARACTER_SCRIPT_TEMPLATE)
	if ResourceSaver.save(_new_character_path + '.gd', character_template) != OK:
		push_error('[Popochiu] Could not create script: %s.gd' % _new_character_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear la instancia del nuevo personaje y asignarle el script creado
	var new_character: PopochiuCharacter = preload(CHARACTER_SCENE).instance()
	#	Primero se asigna el script para que no se vayan a sobrescribir otras
	#	propiedades por culpa de esa asignación.
	new_character.set_script(load(_new_character_path + '.gd'))
	new_character.script_name = _new_character_name
	new_character.name = 'Character' + _new_character_name
	new_character.description = _new_character_name
	new_character.cursor = Constants.CURSOR_TYPE.TALK
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el archivo de la escena
	var new_character_packed_scene: PackedScene = PackedScene.new()
	new_character_packed_scene.pack(new_character)
	if ResourceSaver.save(_new_character_path + '.tscn',\
	new_character_packed_scene) != OK:
		push_error('[Popochiu] Could not create character: %s.tscn' % _new_character_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Crear el Resource del personaje
	var character_resource: PopochiuCharacterData = PopochiuCharacterData.new()
	character_resource.script_name = _new_character_name
	character_resource.scene = _new_character_path + '.tscn'
	character_resource.resource_name = _new_character_name
	if ResourceSaver.save(_new_character_path + '.tres',\
	character_resource) != OK:
		push_error('[Popochiu] Could not create PopochiuCharacterData for character: %s' %\
		_new_character_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Agregar el personaje al Popochiu
	if _main_dock.add_resource_to_popochiu(
		'characters', ResourceLoader.load(_new_character_path + '.tres')
	) != OK:
		push_error('[Popochiu] Could not add the created character to Popochiu: %s' %\
		_new_character_name)
		# TODO: Mostrar retroalimentación en el mismo popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Actualizar la lista de habitaciones en el Dock
	_main_dock.add_to_list(Constants.Types.CHARACTER, _new_character_name)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Abrir la escena creada en el editor
	yield(get_tree().create_timer(0.1), 'timeout')
	_main_dock.ei.select_file(_new_character_path + '.tscn')
	_main_dock.ei.open_scene_from_path(_new_character_path + '.tscn')
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Fin
	hide()

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
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
			])
	else:
		_info.clear()


func _clear_fields() -> void:
	._clear_fields()
	
	_new_character_name = ''
	_new_character_path = ''
