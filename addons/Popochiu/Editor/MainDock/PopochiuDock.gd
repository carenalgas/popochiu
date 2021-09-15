tool
class_name PopochiuDock
extends Panel
# Define un conjunto de botones y otros elementos para centralizar la
# configuración de los diferentes nodos que conforman el juego:
#	Rooms (Props, Hotspots, Regions), Characters, Inventory items, Dialog trees,
#	Interfaz gráfica.

const POPOCHIU_SCENE := 'res://addons/Popochiu/Engine/Popochiu.tscn'
const AUDIO_MANAGER_SCENE :=\
'res://addons/Popochiu/Engine/AudioManager/AudioManager.tscn'
const ROOMS_PATH := 'res://popochiu/Rooms/'
const CHARACTERS_PATH := 'res://popochiu/Characters/'
const INVENTORY_ITEMS_PATH := 'res://popochiu/InventoryItems/'
const DIALOGS_PATH := 'res://popochiu/Dialogs/'
const SEARCH_PATH := 'res://popochiu/'
#const CUES_PATH := 'res://popochiu/AudioManager/Cues'

var ei: EditorInterface
var fs: EditorFileSystem
var dir := Directory.new()
var popochiu: Popochiu = null
# ▓▓▓▓ Room ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
var opened_room: PopochiuRoom = null
# ▓▓▓▓ Audio ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
var audio_manager: Node = null
var last_played: Control = null

var _has_data := false
var _object_row: PackedScene = preload(\
'res://addons/Popochiu/Editor/MainDock/ObjectRow/PopochiuObjectRow.tscn')
# ▓▓▓▓ Audio ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
var _audio_row := preload(\
'res://addons/Popochiu/Editor/MainDock/AudioRow/PopochiuAudioRow.tscn')
# Arreglo con los path a los archivos de audio que ya están asignados a alguno
# de los arreglos de AudioCue en el AudioManager.
var _audio_files_in_group := []
var _audio_files_to_assign := []
# Para contar los AudioCue que se crearon durante la búsqueda de archivos de
# audio. Esto ocurre cuando hay unos prefijos definidos: mx_, sfx_, vo_, ui_.
var _created_audio_cues := 0
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ Audio ▓▓▓▓

onready var delete_dialog: ConfirmationDialog = find_node('DeleteConfirmation')
onready var delete_checkbox: CheckBox = delete_dialog.find_node('CheckBox')
onready var delete_extra: Container = delete_dialog.find_node('Extra')
onready var _tab_container: TabContainer = find_node('TabContainer')
onready var _types := {
	room = {
		path = ROOMS_PATH,
		group = find_node('RoomsGroup'),
		popup = find_node('CreateRoom'),
		scene = ROOMS_PATH + ('%s/Room%s.tscn')
	},
	character = {
		path = CHARACTERS_PATH,
		group = find_node('CharactersGroup'),
		popup = find_node('CreateCharacter'),
		scene = CHARACTERS_PATH + ('%s/Character%s.tscn')
	},
	inventory_item = {
		path = INVENTORY_ITEMS_PATH,
		group = find_node('ItemsGroup'),
		popup = find_node('CreateInventoryItem'),
		scene = INVENTORY_ITEMS_PATH + ('%s/Inventory%s.tscn')
	},
	dialog = {
		path = DIALOGS_PATH,
		group = find_node('DialogsGroup'),
		popup = find_node('CreateDialog'),
		scene = DIALOGS_PATH + ('%s/Dialog%s.tres')
	},
	prop = {
		group = find_node('PropsGroup'),
		popup = find_node('CreateProp')
	},
	hotspot = {
		group = find_node('HotspotsGroup'),
		popup = find_node('CreateHotspot')
	},
	region = {
		group = find_node('RegionsGroup'),
		popup = find_node('CreateRegion')
	},
}

# ▓▓▓▓ Room ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
onready var _room_name: Label = find_node('RoomName')
onready var _no_room_info: Label = find_node('NoRoomInfo')
onready var _props_group: PopochiuGroup = _types['prop'].group
onready var _props_popup: ConfirmationDialog = _types['prop'].popup
onready var _hotspots_group: PopochiuGroup = _types['hotspot'].group
onready var _hotspots_popup: ConfirmationDialog = _types['hotspot'].popup
onready var _regions_group: PopochiuGroup = _types['region'].group
onready var _regions_popup: ConfirmationDialog = _types['region'].popup
onready var _points_group: PopochiuGroup = find_node('PointsGroup')
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ Room ▓▓▓▓

# ▓▓▓▓ Audio ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
onready var _am_unassigned_group: PopochiuGroup = find_node('UnassignedGroup')
onready var _am_groups := {
	mx = {
		array = 'mx_cues',
		group = find_node('MusicGroup')
	},
	sfx = {
		array = 'sfx_cues',
		group = find_node('SFXGroup')
	},
	vo = {
		array = 'vo_cues',
		group = find_node('VoiceGroup')
	},
	ui = {
		array = 'ui_cues',
		group = find_node('UIGroup')
	}
}
onready var _asp: AudioStreamPlayer = find_node('AudioStreamPlayer')
onready var _am_search_files: Button = find_node('BtnSearchAudioFiles')
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ Audio ▓▓▓▓


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	popochiu = load(POPOCHIU_SCENE).instance()
	audio_manager = load(AUDIO_MANAGER_SCENE).instance()
	
	# Que la pestaña seleccionada por defecto sea la principal (Main
	_tab_container.current_tab = 0
	
	# Por defecto deshabilitar los botones hasta que no se haya seleccionado
	# una habitación.
	_room_name.hide()
	_no_room_info.hide()
	
	_am_search_files.icon = get_icon('Search', 'EditorIcons')
	
	# Habilitar todas las pestañas a mano porque Godot está loco
	_tab_container.set_tab_disabled(0, false)
	_tab_container.set_tab_disabled(1, false)
	_tab_container.set_tab_disabled(2, false)
#	_tab_container.set_tab_disabled(3, false)
	
	for t in _types:
		_types[t].popup.set_main_dock(self)
		_types[t].group.connect(
			'create_clicked', self, '_open_popup', [_types[t].popup]
		)
	
	_tab_container.connect('tab_changed', self, '_on_tab_changed')
	_am_search_files.connect('pressed', self, '_search_audio_files')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func fill_data() -> void:
	# Buscar habitaciones, personajes, objetos de inventario y diálogos.
	for t in _types:
		if not _types[t].has('path'): continue
		
		var type_dir: EditorFileSystemDirectory = fs.get_filesystem_path(
			_types[t].path
		)

		for d in type_dir.get_subdir_count():
			var dir: EditorFileSystemDirectory = type_dir.get_subdir(d)
			
			for f in dir.get_file_count():
				var path = dir.get_file_path(f)

				if not fs.get_file_type(path) == "Resource": continue
				
				var resource: Resource = load(path)
				
				if not (resource is PopochiuRoomData
				or resource is PopochiuCharacterData
				or resource is PopochiuInventoryItemData
				or resource is PopochiuDialog):
					continue
				
				_has_data = true

				var row: PopochiuObjectRow = _create_object_row(
					t, resource.script_name
				)
				_types[t].group.add(row)
				
				# Verificar si el objeto en la lista esta en su arreglo respectivo
				# dentro de Popochiu (Popochiu.tscn).
				var is_in_core := true
				
				match t:
					'room':
						is_in_core = popochiu.rooms.has(resource)
					'character':
						is_in_core = popochiu.characters.has(resource)
					'inventory_item':
						is_in_core = popochiu.inventory_items.has(resource)
					'dialog':
						is_in_core = popochiu.dialogs.has(resource)
				
				if not is_in_core:
					row.show_add_to_core()
	
	_fill_audio_tab()
	
	# Buscar archivos de audio sin AudioCue
	_search_audio_files()


func add_to_list(type: String, name_to_add: String) -> void:
	_types[type].group.add(_create_object_row(type, name_to_add))
	
#	_types[type].list.add_child(_create_object_row(type, name_to_add))
#
#	_types[type].list.move_child(
#		_types[type].button, _types[type].list.get_child_count()
#	)
	
	_has_data = true


func scene_changed(scene_root: Node) -> void:
	# Poner todo en su estado por defecto
	opened_room = null

	_room_name.hide()
	_no_room_info.show()
	_props_group.clear_list()
	_hotspots_group.clear_list()
	_regions_group.clear_list()
	_points_group.clear_list()
	
#	if scene_root is Area2D:
	if scene_root is PopochiuRoom:
		# Actualizar la información de la habitación que se abrió
		opened_room = scene_root
		_room_name.text = opened_room.script_name
		
		_room_name.show()
		_props_popup.room_opened()
		_hotspots_popup.room_opened()
		_regions_popup.room_opened()
		
		# Llenar la lista de props
		for p in opened_room.get_props():
			if p is Prop:
				var lbl: Label = Label.new()
				lbl.text = (p as Prop).name
				_props_group.add(lbl)
		
		# Llenar la lista de hotspots
		for h in opened_room.get_hotspots():
			if h is Hotspot:
				var lbl: Label = Label.new()
				lbl.text = (h as Hotspot).name
				_hotspots_group.add(lbl)
		
		# Llenar la lista de regiones
		for r in opened_room.get_regions():
			if r is Region:
				var lbl: Label = Label.new()
				lbl.text = (r as Region).name
				_regions_group.add(lbl)
		
		# Llenar la lista de puntos
		for p in opened_room.get_points():
			if p is Position2D:
				var lbl: Label = Label.new()
				lbl.text = (p as Position2D).name
				_points_group.add(lbl)
		
		_no_room_info.hide()

		_tab_container.current_tab = 1
	else:
		_tab_container.current_tab = 0


func get_popochiu() -> Node:
	popochiu.free()
	popochiu = load(POPOCHIU_SCENE).instance()
	return popochiu


func get_audio_manager() -> Node:
	audio_manager.free()
	audio_manager = load(AUDIO_MANAGER_SCENE).instance()
	return audio_manager


func add_resource_to_popochiu(target: String, resource: Resource) -> int:
	get_popochiu()
	
	if popochiu[target].empty():
		popochiu[target] = [resource]
	else:
		popochiu[target].append(resource)
	
	return save_popochiu()


func save_popochiu() -> int:
	var result := OK
	var new_popochiu: PackedScene = PackedScene.new()
	new_popochiu.pack(popochiu)
	result = ResourceSaver.save(POPOCHIU_SCENE, new_popochiu)
	if result != OK:
		push_error('---- ◇ Error al actualizar Popochiu: %d ◇ ----' % result)
		return result

	ei.reload_scene_from_path(POPOCHIU_SCENE)

	# TODO: Hacer esto sólo si la escena de Popochiu está entre las pestañas
	#		abiertas en el editor.
	if ei.get_edited_scene_root().name == 'Popochiu':
		ei.save_scene()

	return result


func save_audio_manager() -> int:
	var result := OK
	
	var new_audio_manager: PackedScene = PackedScene.new()
	new_audio_manager.pack(audio_manager)
	
	result = ResourceSaver.save(AUDIO_MANAGER_SCENE, new_audio_manager)
	
	assert(result == OK, 'No se pudo guardar el AudioManager')
	
		# Guardar los cambios en la escena del AudioManager
	ei.reload_scene_from_path(AUDIO_MANAGER_SCENE)

	if ei.get_edited_scene_root().name == 'AudioManager':
		ei.save_scene()
	
	return result


func show_confirmation(title: String, message: String, ask := '') -> void:
	delete_checkbox.pressed = false
	
	delete_dialog.window_title = title
	delete_dialog.find_node('Message').bbcode_text = message
	
	delete_extra.hide()
	if ask:
		delete_dialog.find_node('Ask').bbcode_text = ask
		delete_extra.show()
	
	delete_dialog.popup_centered()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _open_popup(popup: Popup) -> void:
	popup.popup_centered_clamped(Vector2(640, 360))


func _create_object_row(type: String, name_to_add: String) -> PopochiuObjectRow:
	var new_obj: PopochiuObjectRow = _object_row.instance()

	new_obj.name = name_to_add
	new_obj.type = type
	new_obj.path = _types[type].scene % [name_to_add, name_to_add]
	new_obj.main_dock = self
	
	return new_obj


func _on_tab_changed(tab: int) -> void:
	if not _has_data and tab == 0:
		# Intentar cargar los datos de la pestaña Main si por alguna razón no
		# se pudieron leer los directorios al abrir el motor.
		fill_data()


func _fill_audio_tab() -> void:
	# Poner los AudioCue ya cargados en el AudioManager en su respectivo grupo
	for d in _am_groups:
		var group: Dictionary = _am_groups[d]
		
		if not audio_manager[group.array].empty():
			for m in audio_manager[group.array]:
				if (m as AudioCue).audio.resource_path in _audio_files_in_group:
					continue
				
				var ar := _create_audio_cue_row(m)
				ar.cue_group = group.array
				group.group.add(ar)
				
				_audio_files_in_group.append(
					(m as AudioCue).audio.resource_path
				)


func _create_audio_cue_row(audio_cue: AudioCue) -> HBoxContainer:
	var ar: HBoxContainer = _audio_row.instance()
	
	ar.audio_cue = audio_cue
	ar.main_dock = self
	ar.stream_player = _asp
	
	ar.connect('deleted', self, '_audio_cue_deleted')
	
	return ar


func _search_audio_files() -> void:
	_created_audio_cues = 0
	
	_read_directory(fs.get_filesystem_path(SEARCH_PATH))
	
	if _created_audio_cues > 0:
		_fill_audio_tab()


func _read_directory(dir: EditorFileSystemDirectory) -> void:
	if dir.get_subdir_count():
		for d in dir.get_subdir_count():
			# Revisar las subcarpetas
			_read_directory(dir.get_subdir(d))

			# Buscar en los archivos de la carpeta
			_read_files(dir)
	else:
		_read_files(dir)


func _read_files(dir: EditorFileSystemDirectory) -> void:
	for idx in dir.get_file_count():
		var file_name = dir.get_file(idx)
		
		if file_name.get_extension() == "ogg" or \
		file_name.get_extension() == "mp3" or \
		file_name.get_extension() == "wav" or \
		file_name.get_extension() == "opus":
			if dir.get_file_path(idx) in _audio_files_in_group\
			or dir.get_file_path(idx) in _audio_files_to_assign:
				# No poner en la lista un archivo de audio que ya está asignado
				# a un AudioCue en el AudioManager.
				continue
			
			# Ver si el prefijo del archivo coincide con los definidos para
			# asignación automática: mx_, sfx_, vo_, ui_.
			
			if file_name.find('mx_') > -1:
				_create_audio_cue('music', dir.get_file_path(idx))
				_created_audio_cues += 1
			elif file_name.find('sfx_') > -1:
				_create_audio_cue('sfx', dir.get_file_path(idx))
				_created_audio_cues += 1
			elif file_name.find('vo_') > -1:
				_create_audio_cue('voice', dir.get_file_path(idx))
				_created_audio_cues += 1
			elif file_name.find('ui_') > -1:
				_create_audio_cue('ui', dir.get_file_path(idx))
				_created_audio_cues += 1
			else:
				_create_audio_file_row(dir.get_file_path(idx))


func _create_audio_file_row(file_path: String) -> void:
	var ar: HBoxContainer = _audio_row.instance()
	
	ar.name = file_path.get_file().get_basename()
	ar.file_name = file_path.get_file()
	ar.file_path = file_path
	ar.main_dock = self
	ar.stream_player = _asp
	
	ar.connect('target_clicked', self, '_create_audio_cue', [file_path, ar])
	
	_am_unassigned_group.add(ar)
	
	_audio_files_to_assign.append(file_path)


func _create_audio_cue(
		type: String, path: String, audio_row: Container = null
	) -> void:
	var cue_name := path.get_file().get_basename()
	var cue_file_name := Utils.snake2pascal(cue_name)
	cue_file_name += '.tres'
	
	# Crear el AudioCue que se guardará en disco y guardarlo en disco.
	var ac: AudioCue = AudioCue.new()
	var stream: AudioStream = load(path)
	ac.audio = stream
	ac.resource_name = cue_name.to_lower()
	
	var error: int = ResourceSaver.save(
#		'%s/%s' % [CUES_PATH, cue_file_name],
		'%s/%s' % [path.get_base_dir(), cue_file_name],
		ac
	)
	
	assert(error == OK, 'No se pudo guardar el AudioCue: %s' % cue_file_name)
	
	# Agregar el AudioCue creado a su diccionario en el AudioManager
	audio_manager.free()
	audio_manager = load(AUDIO_MANAGER_SCENE).instance()
	
	var resource: AudioCue = load('%s/%s' % [path.get_base_dir(), cue_file_name])
	var target := ''
	
	match type:
		'music':
			target = 'mx_cues'
		'sfx':
			target = 'sfx_cues'
		'voice':
			target = 'vo_cues'
		'ui':
			target = 'ui_cues'
	
	if audio_manager[target].empty():
		audio_manager[target] = [resource]
	else:
		audio_manager[target].append(resource)
	
	audio_manager[target].sort_custom(A, '_sort_cues')
	
	save_audio_manager()
	
	if is_instance_valid(audio_row):
		# Eliminar la fila del archivo
		_audio_files_to_assign.erase(path)
		audio_row.queue_free()
	
		# Agregar la fila al grupo correspondiente
		yield(get_tree().create_timer(0.1), 'timeout')
		_fill_audio_tab()


func _audio_cue_deleted(file_path: String) -> void:
	_audio_files_in_group.erase(file_path)
	_create_audio_file_row(file_path)
