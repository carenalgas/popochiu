# Acts like a HUD for working with Popochiu's objects:
# Rooms, Characters, Inventory items, Dialog trees.
@tool
extends Panel

signal move_folders_pressed

const POPOCHIU_SCENE := 'res://addons/popochiu/engine/popochiu.tscn'
const ROOMS_PATH := 'res://popochiu/rooms/'
const CHARACTERS_PATH := 'res://popochiu/characters/'
const INVENTORY_ITEMS_PATH := 'res://popochiu/inventory_items/'
const DIALOGS_PATH := 'res://popochiu/dialogs/'
const Constants := preload('res://addons/popochiu/popochiu_resources.gd')
const PopochiuObjectRow := preload('object_row/popochiu_object_row.gd')

var ei: EditorInterface
var fs: EditorFileSystem
var popochiu: Node = null
var last_selected: PopochiuObjectRow = null

var _has_data := false
var _object_row: PackedScene = preload(\
'res://addons/popochiu/editor/main_dock/object_row/popochiu_object_row.tscn')
var _rows_paths := []

@onready var delete_dialog: ConfirmationDialog = find_child('DeleteConfirmation')
@onready var delete_checkbox: CheckBox = delete_dialog.find_child('CheckBox')
@onready var delete_message: RichTextLabel = delete_dialog.find_child('Message')
@onready var delete_extra: Container = delete_dialog.find_child('Extra')
@onready var delete_ask: RichTextLabel = delete_extra.find_child('Ask')
@onready var loading_dialog: Popup = find_child('Loading')
@onready var setup_dialog: AcceptDialog = find_child('Setup')
@onready var _tab_container: TabContainer = find_child('TabContainer')
@onready var _tab_room: VBoxContainer = _tab_container.get_node('Room')
@onready var _tab_audio: VBoxContainer = _tab_container.get_node('Audio')
# ▨▨▨▨ FOOTER ▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨▨
@onready var _btn_docs: Button = find_child('BtnDocs')
@onready var _btn_settings: Button = find_child('BtnSettings')
@onready var _btn_setup: Button = find_child('BtnSetup')
@onready var _version: Label = find_child('Version')
@onready var _types := {
	Constants.Types.ROOM: {
		path = ROOMS_PATH,
		group = find_child('RoomsGroup'),
		popup = find_child('CreateRoom'),
		scene = ROOMS_PATH + ('%s/room_%s.tscn')
	},
	Constants.Types.CHARACTER: {
		path = CHARACTERS_PATH,
		group = find_child('CharactersGroup'),
		popup = find_child('CreateCharacter'),
		scene = CHARACTERS_PATH + ('%s/character_%s.tscn')
	},
	Constants.Types.INVENTORY_ITEM: {
		path = INVENTORY_ITEMS_PATH,
		group = find_child('ItemsGroup'),
		popup = find_child('CreateInventoryItem'),
		scene = INVENTORY_ITEMS_PATH + ('%s/item_%s.tscn')
	},
	Constants.Types.DIALOG: {
		path = DIALOGS_PATH,
		group = find_child('DialogsGroup'),
		popup = find_child('CreateDialog'),
		scene = DIALOGS_PATH + ('%s/dialog_%s.tres')
	}
}


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	popochiu = load(POPOCHIU_SCENE).instantiate()
	_tab_container.get_node('Main/PopochiuFilter').groups = _types
	
	_btn_setup.icon = get_theme_icon("Edit", "EditorIcons")
	_btn_settings.icon = get_theme_icon('Tools', 'EditorIcons')
	_btn_docs.icon = get_theme_icon('HelpSearch', 'EditorIcons')
	_version.text = 'v' + PopochiuResources.get_version()
	
	delete_message.add_theme_font_override('bold_font', get_theme_font('bold', 'EditorFonts'))
	delete_ask.add_theme_font_override('bold_font', get_theme_font('bold', 'EditorFonts'))
	
	# Set the Main tab selected by default
	_tab_container.current_tab = 0
	
	# Connect to children signals
	for t in _types:
		_types[t].popup.set_main_dock(self)
		_types[t].group.create_clicked.connect(_open_popup.bind(_types[t].popup))
	
	_tab_room.main_dock = self
	_tab_room.object_row = _object_row
	_tab_audio.main_dock = self
	
	_tab_container.tab_changed.connect(_on_tab_changed)
	_btn_docs.pressed.connect(OS.shell_open.bind(Constants.WIKI))
	_btn_settings.pressed.connect(_open_settings)
	_btn_setup.pressed.connect(open_setup)
	get_tree().node_added.connect(_check_node)


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
				[resource.resource_name, resource.resource_name]
				
				if row_path in _rows_paths: continue
				
				var row: PopochiuObjectRow = _create_object_row(
					t, resource.script_name
				)
				_types[t].group.add(row)
				
				# Check if the object in the list is in its corresponding array
				# in Popochiu (Popochiu.tscn)
				var is_in_core := true
				var has_state_script: bool = FileAccess.file_exists(
					row.path.replace('.tscn', '_state.gd')
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
						
						if resource.script_name ==\
						PopochiuResources.get_data_value('setup', 'pc', ''):
							row.is_pc = true
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
				else:
					row.remove_create_state_script()
	
	# Load other tabs data
	_tab_audio.fill_data()


func add_to_list(type: int, name_to_add: String) -> PopochiuObjectRow:
	var row := _create_object_row(type, name_to_add)
	_types[type].group.add(row)
	return row


func scene_changed(scene_root: Node) -> void:
	if not is_instance_valid(_tab_room): return
	_tab_room.scene_changed(scene_root)


func scene_closed(filepath: String) -> void:
	if not is_instance_valid(_tab_room): return
	_tab_room.scene_closed(filepath)


func add_resource_to_popochiu(target: String, resource: Resource) -> int:
	return PopochiuResources.set_data_value(
		target, resource.script_name, resource.resource_path
	)


func show_confirmation(
	title: String, message: String, ask := '', min_size := Vector2(640, 120)
) -> void:
	delete_checkbox.button_pressed = false
	
	delete_dialog.title = title
	delete_message.text = message
	
	delete_extra.hide()
	
	if ask:
		delete_ask.text = ask
		delete_extra.show()
	
	delete_dialog.popup_centered(min_size)


func get_popup(name: String) -> ConfirmationDialog:
	return find_child(name) as ConfirmationDialog


func set_main_scene(path: String) -> void:
	ProjectSettings.set_setting('application/run/main_scene', path)
	
	var result = ProjectSettings.save()
	assert(result == OK) #,'[Popochiu] Failed to save project settings')
	
	_types[Constants.Types.ROOM].group.clear_favs()


func set_pc(script_name: String) -> void:
	PopochiuResources.set_data_value('setup', 'pc', script_name)
	_types[Constants.Types.CHARACTER].group.clear_favs()


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
func _open_popup(popup: ConfirmationDialog) -> void:
	popup.clear_fields()
	popup.popup_centered(Vector2(640.0, 160.0))


func _create_object_row(type: int, name_to_add: String) -> PopochiuObjectRow:
	var new_obj: PopochiuObjectRow = _object_row.instantiate()

	new_obj.name = name_to_add
	new_obj.type = type
	new_obj.path = _types[type].scene % [
		name_to_add.to_snake_case(), name_to_add.to_snake_case()
	]
	new_obj.main_dock = self
	new_obj.clicked.connect(_select_object)
	
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
		last_selected.deselect()
	
	last_selected = por


func _open_settings() -> void:
	ei.edit_resource(PopochiuResources.get_settings())


func _check_node(node: Node) -> void:
	if node is PopochiuCharacter and node.get_parent() is Node2D:
		# The node is a PopochiuCharacter in a room
		node.name = 'Character%s *' % node.script_name
		# TODO: Show something in the Inspector to alert devs about editing this
		# node.
