tool
extends Panel
# Acts like a HUD for working with Popochiu's objects:
# Rooms, Characters, Inventory items, Dialog trees.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

signal move_folders_pressed

const POPOCHIU_SCENE := 'res://addons/Popochiu/Engine/Popochiu.tscn'
const ROOMS_PATH := 'res://popochiu/Rooms/'
const CHARACTERS_PATH := 'res://popochiu/Characters/'
const INVENTORY_ITEMS_PATH := 'res://popochiu/InventoryItems/'
const DIALOGS_PATH := 'res://popochiu/Dialogs/'
const Constants := preload('res://addons/Popochiu/PopochiuResources.gd')
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
onready var loading_dialog: Popup = find_node('Loading')
onready var setup_dialog: Popup = find_node('Setup')
onready var _tab_container: TabContainer = find_node('TabContainer')
onready var _tab_room: VBoxContainer = _tab_container.get_node('Room')
onready var _tab_audio: VBoxContainer = _tab_container.get_node('Audio')
# ▨▨▨▨ FOOTER ▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨
onready var _btn_docs: Button = find_node('BtnDocs')
onready var _btn_settings: Button = find_node('BtnSettings')
onready var _btn_setup: Button = find_node('BtnSetup')
onready var _version: Label = find_node('Version')
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
	
	_btn_setup.icon = get_icon("Edit", "EditorIcons")
	_btn_settings.icon = get_icon('Tools', 'EditorIcons')
	_btn_docs.icon = get_icon('HelpSearch', 'EditorIcons')
	_version.text = 'v' + PopochiuResources.get_version()
	
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
	
	_tab_container.connect('tab_changed', self, '_on_tab_changed')
	
	_btn_docs.connect('pressed', OS, 'shell_open', [Constants.WIKI])
	_btn_settings.connect('pressed', self, '_open_settings')
	_btn_setup.connect('pressed', self, 'open_setup')
	
	get_tree().connect('node_added', self, '_check_node')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func fill_data() -> void:
	var settings := PopochiuResources.get_settings()
	
	# Search the FileSystem for Rooms, Characters, InventoryItems and Dialogs
	for t in _types:
		if not _types[t].has('path'): continue
		
		var type_dir: EditorFileSystemDirectory = fs.get_filesystem_path(
			_types[t].path
		)
		
		if not is_instance_valid(type_dir):
			continue
		
		for d in type_dir.get_subdir_count():
			var efsd: EditorFileSystemDirectory = type_dir.get_subdir(d)
			
			for f in efsd.get_file_count():
				var path = efsd.get_file_path(f)
				
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
				var has_state_script: bool = dir.file_exists(
					row.path.replace('.tscn', 'State.gd')
				)
				
				match t:
					Constants.Types.ROOM:
						is_in_core = PopochiuResources.has_data_value(
							'rooms', resource.script_name
						)
						
						# Check if the room is the main scene
						var main_scene: String = ProjectSettings.get_setting(
							PopochiuResources.MAIN_SCENE
						)
						if main_scene == resource.scene:
							row.is_main = true
					Constants.Types.CHARACTER:
						is_in_core = PopochiuResources.has_data_value(
							'characters', resource.script_name
						)
					Constants.Types.INVENTORY_ITEM:
						is_in_core = PopochiuResources.has_data_value(
							'inventory_items', resource.script_name
						)
						
						if resource.script_name in settings.items_on_start:
							row.is_on_start = true
					Constants.Types.DIALOG:
						is_in_core = PopochiuResources.has_data_value(
							'dialogs', resource.script_name
						)
				
				if not is_in_core:
					row.show_add_to_core()
				
				if not has_state_script:
					row.show_create_state_script()
	
	# Load other tabs data
	_tab_audio.fill_data()


func add_to_list(type: int, name_to_add: String) -> PopochiuObjectRow:
	var row := _create_object_row(type, name_to_add)
	_types[type].group.add(row)
	return row


func scene_changed(scene_root: Node) -> void:
	_tab_room.scene_changed(scene_root)


func scene_closed(filepath: String) -> void:
	_tab_room.scene_closed(filepath)


func add_resource_to_popochiu(target: String, resource: Resource) -> int:
	return PopochiuResources.set_data_value(
		target, resource.script_name, resource.resource_path
	)


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


func get_opened_room() -> PopochiuRoom:
	return _tab_room.opened_room


func open_setup() -> void:
	setup_dialog.appear()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _open_popup(popup: Popup) -> void:
	popup.popup_centered_minsize(Vector2(640, 360))


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
	if last_selected and last_selected != por:
		last_selected.unselect()
	
	last_selected = por


func _open_settings() -> void:
	ei.edit_resource(PopochiuResources.get_settings())


func _check_node(node: Node) -> void:
	if node is PopochiuCharacter and node.get_parent() is YSort:
		# The node is a PopochiuCharacter in a room
		node.name = 'Character%s *' % node.script_name
		# TODO: Show something in the Inspector to alert devs about editing this
		# node.
