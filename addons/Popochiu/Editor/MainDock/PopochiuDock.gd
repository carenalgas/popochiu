tool
class_name PopochiuDock
extends Panel
# Define un conjunto de botones y otros elementos para centralizar la
# configuración de los diferentes nodos que conforman el juego:
#	Rooms (Props, Hotspots, Regions), Characters, Inventory items, Dialog trees,
#	Interfaz gráfica.

const POPOCHIU_SCENE := 'res://addons/Popochiu/Engine/Popochiu.tscn'
const ROOMS_PATH := 'res://popochiu/Rooms/'
const CHARACTERS_PATH := 'res://popochiu/Characters/'
const INVENTORY_ITEMS_PATH := 'res://popochiu/InventoryItems/'
const DIALOGS_PATH := 'res://popochiu/Dialogs/'

var ei: EditorInterface
var fs: EditorFileSystem
var dir := Directory.new()
var popochiu: Popochiu = null
var last_selected: PopochiuObjectRow = null

var _has_data := false
var _object_row: PackedScene = preload(\
'res://addons/Popochiu/Editor/MainDock/ObjectRow/PopochiuObjectRow.tscn')

onready var delete_dialog: ConfirmationDialog = find_node('DeleteConfirmation')
onready var delete_checkbox: CheckBox = delete_dialog.find_node('CheckBox')
onready var delete_extra: Container = delete_dialog.find_node('Extra')
onready var _tab_container: TabContainer = find_node('TabContainer')
onready var tab_room: VBoxContainer = _tab_container.get_node('Room')
onready var tab_audio: VBoxContainer = _tab_container.get_node('Audio')
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
	}
}


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	popochiu = load(POPOCHIU_SCENE).instance()
	
	# Que la pestaña seleccionada por defecto sea la principal (Main
	_tab_container.current_tab = 0
	
	# Habilitar todas las pestañas a mano porque Godot está loco
	_tab_container.set_tab_disabled(0, false)
	_tab_container.set_tab_disabled(1, false)
	_tab_container.set_tab_disabled(2, false)
#	_tab_container.set_tab_disabled(3, false)
	
	# Conectar señales de los hijos
	for t in _types:
		_types[t].popup.set_main_dock(self)
		_types[t].group.connect(
			'create_clicked', self, '_open_popup', [_types[t].popup]
		)
	
	tab_room.main_dock = self
	tab_audio.main_dock = self
	_tab_container.connect('tab_changed', self, '_on_tab_changed')


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
						
						# Ver si la habitación es la principal
						var main_scene: String = ProjectSettings.get_setting(\
						'application/run/main_scene')
						if main_scene == resource.scene:
							row.is_main = true
					'character':
						is_in_core = popochiu.characters.has(resource)
					'inventory_item':
						is_in_core = popochiu.inventory_items.has(resource)
					'dialog':
						is_in_core = popochiu.dialogs.has(resource)
				
				if not is_in_core:
					row.show_add_to_core()
	
	tab_audio.fill_data()


func add_to_list(type: String, name_to_add: String) -> void:
	_types[type].group.add(_create_object_row(type, name_to_add))
	
	_has_data = true


func scene_changed(scene_root: Node) -> void:
	tab_room.scene_changed(scene_root)


func get_popochiu() -> Node:
	popochiu.free()
	popochiu = load(POPOCHIU_SCENE).instance()
	return popochiu


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


func show_confirmation(title: String, message: String, ask := '') -> void:
	delete_checkbox.pressed = false
	
	delete_dialog.window_title = title
	delete_dialog.find_node('Message').bbcode_text = message
	
	delete_extra.hide()
	if ask:
		delete_dialog.find_node('Ask').bbcode_text = ask
		delete_extra.show()
	
	delete_dialog.popup_centered()


func get_popup(name: String) -> ConfirmationDialog:
	return find_node(name) as ConfirmationDialog


func set_main_scene(path: String) -> void:
	ProjectSettings.set_setting('application/run/main_scene', path)
	
	var result = ProjectSettings.save()
	assert(result == OK, 'Failed to save project settings')
	
	_types['room'].group.clear_favs()


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
