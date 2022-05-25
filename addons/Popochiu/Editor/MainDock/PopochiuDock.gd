tool
extends Panel
# Acts like a HUD for working with Popochiu's objects:
# Rooms, Characters, Inventory items, Dialog trees.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

signal room_row_clicked
signal move_folders_pressed

const POPOCHIU_SCENE := 'res://addons/Popochiu/Engine/Popochiu.tscn'
const ROOMS_PATH := 'res://popochiu/Rooms/'
const CHARACTERS_PATH := 'res://popochiu/Characters/'
const INVENTORY_ITEMS_PATH := 'res://popochiu/InventoryItems/'
const DIALOGS_PATH := 'res://popochiu/Dialogs/'
const Constants := preload('res://addons/Popochiu/Constants.gd')
const PopochiuObjectRow := preload('ObjectRow/PopochiuObjectRow.gd')

var ei: EditorInterface
var fs: EditorFileSystem
var dir := Directory.new()
var popochiu: Node = null
var last_selected: PopochiuObjectRow = null

var _has_data := false
var _object_row: PackedScene = preload(\
'res://addons/Popochiu/Editor/MainDock/ObjectRow/PopochiuObjectRow.tscn')
var _rows_paths := []

onready var delete_dialog: ConfirmationDialog = find_node('DeleteConfirmation')
onready var delete_checkbox: CheckBox = delete_dialog.find_node('CheckBox')
onready var delete_extra: Container = delete_dialog.find_node('Extra')
onready var _btn_move_folders: Button = find_node('BtnMoveFolders')
onready var _tab_container: TabContainer = find_node('TabContainer')
onready var _tab_room: VBoxContainer = _tab_container.get_node('Room')
onready var _tab_audio: VBoxContainer = _tab_container.get_node('Audio')
onready var _tab_settings: VBoxContainer = _tab_container.get_node('Settings')
onready var _btn_docs: Button = find_node('BtnDocs')
onready var _types := {
	Constants.Types.ROOM: {
		path = ROOMS_PATH,
		group = find_node('RoomsGroup'),
		popup = find_node('CreateRoom'),
		scene = ROOMS_PATH + ('%s/Room%s.tscn')
	},
	Constants.Types.CHARACTER: {
		path = CHARACTERS_PATH,
		group = find_node('CharactersGroup'),
		popup = find_node('CreateCharacter'),
		scene = CHARACTERS_PATH + ('%s/Character%s.tscn')
	},
	Constants.Types.INVENTORY_ITEM: {
		path = INVENTORY_ITEMS_PATH,
		group = find_node('ItemsGroup'),
		popup = find_node('CreateInventoryItem'),
		scene = INVENTORY_ITEMS_PATH + ('%s/Inventory%s.tscn')
	},
	Constants.Types.DIALOG: {
		path = DIALOGS_PATH,
		group = find_node('DialogsGroup'),
		popup = find_node('CreateDialog'),
		scene = DIALOGS_PATH + ('%s/Dialog%s.tres')
	}
}


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	popochiu = load(POPOCHIU_SCENE).instance()
	
	_btn_move_folders.icon = get_icon('MoveUp', 'EditorIcons')
	_btn_docs.icon = get_icon('HelpSearch', 'EditorIcons')
	
	# Set the Main tab selected by default
	_tab_container.current_tab = 0
	
	# Connect to children signals
	for t in _types:
		_types[t].popup.set_main_dock(self)
		_types[t].group.connect(
			'create_clicked', self, '_open_popup', [_types[t].popup]
		)
	
	_tab_room.main_dock = self
	_tab_room.object_row = _object_row
	_tab_audio.main_dock = self
	_tab_settings.main_dock = self
	
	_tab_container.connect('tab_changed', self, '_on_tab_changed')
	_tab_room.connect('row_clicked', self, 'emit_signal', ['room_row_clicked'])
	
	_btn_docs.connect('pressed', OS, 'shell_open', [Constants.WIKI])
	
	_btn_move_folders.hide()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func fill_data() -> void:
	# Buscar habitaciones, personajes, objetos de inventario y diálogos.
	for t in _types:
		if not _types[t].has('path'): continue
		
		var type_dir: EditorFileSystemDirectory = fs.get_filesystem_path(
			_types[t].path
		)
		
		if not is_instance_valid(type_dir):
			continue
		
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
				
				var row_path: String = _types[t].scene %\
				[resource.script_name, resource.script_name]
				
				if row_path in _rows_paths: continue
				
				var row: PopochiuObjectRow = _create_object_row(
					t, resource.script_name
				)
				_types[t].group.add(row)
				
				# Check if the object in the list is in its corresponding array
				# in Popochiu (Popochiu.tscn)
				var is_in_core := true
				
				match t:
					Constants.Types.ROOM:
						is_in_core = popochiu.rooms.has(resource)
						
						# Check if the room is the main scene
						var main_scene: String = ProjectSettings.get_setting(\
						'application/run/main_scene')
						if main_scene == resource.scene:
							row.is_main = true
					Constants.Types.CHARACTER:
						is_in_core = popochiu.characters.has(resource)
					Constants.Types.INVENTORY_ITEM:
						is_in_core = popochiu.inventory_items.has(resource)
						
						if resource.script_name in popochiu.items_on_start:
							row.is_on_start = true
					Constants.Types.DIALOG:
						is_in_core = popochiu.dialogs.has(resource)
				
				if not is_in_core:
					row.show_add_to_core()
	
	# Load other tabs data
	_tab_audio.fill_data()
	_tab_settings.fill_data()


func add_to_list(type: int, name_to_add: String) -> PopochiuObjectRow:
	var row := _create_object_row(type, name_to_add)
	_types[type].group.add(row)
	return row


func scene_changed(scene_root: Node) -> void:
	_tab_room.scene_changed(scene_root)


func scene_closed(filepath: String) -> void:
	_tab_room.scene_closed(filepath)


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
		push_error('[Popochiu] ---- ◇ Update error: %d ◇ ----' % result)
		return result
	
	ei.reload_scene_from_path(POPOCHIU_SCENE)
	
	# TODO: Do this when Popochiu.tscn is part of the opened tabs in the editor
	if ei.get_edited_scene_root() \
	and ei.get_edited_scene_root().name == 'Popochiu':
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
	assert(result == OK, '[Popochiu] Failed to save project settings')
	
	_types[Constants.Types.ROOM].group.clear_favs()


func search_audio_files() -> void:
	if not is_instance_valid(_tab_audio): return
	
	_tab_audio.search_audio_files()


func get_audio_tab() -> Node:
	return _tab_audio


func show_move_folders_button() -> void:
	_btn_move_folders.connect(
		'pressed', self, 'emit_signal', ['move_folders_pressed']
	)
	_btn_move_folders.show()


func hide_move_folders_button() -> void:
	_btn_move_folders.disconnect('pressed', self, 'emit_signal')
	_btn_move_folders.hide()


func get_opened_room() -> PopochiuRoom:
	return _tab_room.opened_room


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _open_popup(popup: Popup) -> void:
	popup.popup_centered_clamped(Vector2(640, 360))


func _create_object_row(type: int, name_to_add: String) -> PopochiuObjectRow:
	var new_obj: PopochiuObjectRow = _object_row.instance()

	new_obj.name = name_to_add
	new_obj.type = type
	new_obj.path = _types[type].scene % [name_to_add, name_to_add]
	new_obj.main_dock = self
	new_obj.connect('clicked', self, '_select_object')
	
	_rows_paths.append(new_obj.path)
	
	_has_data = true
	
	return new_obj


func _on_tab_changed(tab: int) -> void:
	if not _has_data and tab == 0:
		# Try to load the Main tab data in case they couldn't be loaded while
		# opening the engine
		fill_data()


func _select_object(por: PopochiuObjectRow) -> void:
	if last_selected:
		last_selected.unselect()
	
	ei.select_file(por.path)
	last_selected = por
