# The row that is created for Rooms, Characters, Inventory items, Dialogs,
# Props, Hotspots, Regions and Markers in the dock.
@tool
extends HBoxContainer

signal clicked(node)

enum MenuOptions {
	ADD_TO_CORE,
	CREATE_STATE_SCRIPT,
	SET_AS_MAIN,
	SET_AS_PC,
	START_WITH_IT,
	CREATE_PROP_SCRIPT,
	DELETE
}

const SELECTED_FONT_COLOR := Color('706deb')
const PLAYER_CHARACTER_ICON := preload(\
'res://addons/popochiu/icons/player_character.png')
const INVENTORY_START_ICON := preload(\
'res://addons/popochiu/icons/inventory_item_start.png')
const ROOM_STATE_TEMPLATE :=\
'res://addons/popochiu/engine/templates/room_state_template.gd'
const CHARACTER_STATE_TEMPLATE :=\
'res://addons/popochiu/engine/templates/character_state_template.gd'
const INVENTORY_ITEM_STATE_TEMPLATE :=\
'res://addons/popochiu/engine/templates/inventory_item_state_template.gd'
const PROP_SCRIPT_TEMPLATE :=\
'res://addons/popochiu/engine/templates/prop_template.gd'
const Constants := preload('res://addons/popochiu/popochiu_resources.gd')
const AudioCue := preload('res://addons/popochiu/engine/audio_manager/audio_cue.gd')

var type := -1
var path := ''
var node_path := ''
var main_dock: Panel : set = set_main_dock
var is_main := false : set = set_is_main
var is_pc := false : set = set_is_pc
var is_on_start := false : set = set_is_on_start
var is_menu_hidden := false

var _delete_dialog: ConfirmationDialog
var _delete_all_checkbox: CheckBox

@onready var _label: Label = find_child('Label')
@onready var _dflt_font_color: Color = _label.get_theme_color('font_color')
@onready var _fav_icon: TextureRect = find_child('FavIcon')
@onready var _menu_btn: MenuButton = find_child('MenuButton')
@onready var _menu_popup: PopupMenu = _menu_btn.get_popup()
@onready var _btn_open: Button = find_child('Open')
@onready var _btn_script: Button = find_child('Script')
@onready var _btn_state: Button = find_child('State')
@onready var _btn_state_script: Button = find_child('StateScript')
@onready var _menu_cfg: Array = [
	# Room, Character, Inventory item, Dialog
	{
		id = MenuOptions.ADD_TO_CORE,
		icon = preload(\
		'res://addons/popochiu/editor/main_dock/object_row/add_to_core.png'),
		label = 'Add to Popochiu',
		types = Constants.MAIN_TYPES
	},
	{
		id = MenuOptions.CREATE_STATE_SCRIPT,
		icon = get_theme_icon('ScriptCreate', 'EditorIcons'),
		label = 'Create state script',
		types = Constants.MAIN_TYPES
	},
	# Room
	{
		id = MenuOptions.SET_AS_MAIN,
		icon = get_theme_icon('Heart', 'EditorIcons'),
		label = 'Set as Main scene',
		types = [Constants.Types.ROOM]
	},
	# Character
	{
		id = MenuOptions.SET_AS_PC,
		icon = PLAYER_CHARACTER_ICON,
		label = 'Set as Player Character',
		types = [Constants.Types.CHARACTER]
	},
	# Inventory item
	{
		id = MenuOptions.START_WITH_IT,
		icon = INVENTORY_START_ICON,
		label = 'Start with it',
		types = [Constants.Types.INVENTORY_ITEM]
	},
	# Prop
	{
		id = MenuOptions.CREATE_PROP_SCRIPT,
		icon = get_theme_icon('ScriptCreate', 'EditorIcons'),
		label = 'Create script',
		types = [Constants.Types.PROP]
	},
	null,
	{
		id = MenuOptions.DELETE,
		icon = get_theme_icon('Remove', 'EditorIcons'),
		label = 'Remove'
	}
]
@onready var buttons_container: HBoxContainer = $Panel/ButtonsContainer


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	_label.text = str(name)
	tooltip_text = path
	
	# Assign icons
	_fav_icon.texture = get_theme_icon('Heart', 'EditorIcons')
	
	match type:
		Constants.Types.CHARACTER:
			_fav_icon.texture = PLAYER_CHARACTER_ICON
		Constants.Types.INVENTORY_ITEM:
			_fav_icon.texture = INVENTORY_START_ICON
	
	_btn_open.icon = get_theme_icon('InstanceOptions', 'EditorIcons')
	_btn_script.icon = get_theme_icon('Script', 'EditorIcons')
	_btn_state.icon = get_theme_icon('Object', 'EditorIcons')
	_btn_state_script.icon = get_theme_icon('GDScript', 'EditorIcons')
	_menu_btn.icon = get_theme_icon('GuiTabMenuHl', 'EditorIcons')
	
	_btn_script.show()
	_btn_state.show()
	_btn_state_script.show()
	
	# Create the context menu based checked the type of Object this row represents
	_create_menu()
	
	if type in Constants.MAIN_TYPES:
		# By default disable the Add to Popochiu button. This will be enabled
		# by PopochiuDock.gd if this object is not in PopochiuData.cfg
		_menu_popup.set_item_disabled(
			_menu_popup.get_item_index(MenuOptions.ADD_TO_CORE), true
		)
		_menu_popup.set_item_disabled(
			_menu_popup.get_item_index(MenuOptions.CREATE_STATE_SCRIPT), true
		)
	elif type == Constants.Types.PROP and path.find('.gd') > -1:
		# If the Room object has a script, disable the Create prop script button
		_menu_popup.remove_item(
			_menu_popup.get_item_index(MenuOptions.CREATE_PROP_SCRIPT)
		)
	
	if is_menu_hidden:
		_menu_btn.hide()
	
	# Hide buttons based checked the type of the Object this row represents
	_fav_icon.hide()
	
	if type in Constants.ROOM_TYPES:
		if (type == Constants.Types.PROP and\
		not FileAccess.file_exists(path.replace('.tscn', '.gd'))) or (
			type != Constants.Types.PROP and path.find('.gd') == -1
		):
			_btn_script.hide()
		
		_btn_state.hide()
		_btn_state_script.hide()
	
	if type in Constants.ROOM_TYPES:
		# Do not show the button to open this Object' scene if it is a Room
		# Object (Prop, Hotspot, Region, Point)
		_btn_open.hide()
	
	gui_input.connect(_check_click)
	_menu_popup.id_pressed.connect(_menu_item_pressed)
	_btn_open.pressed.connect(_open)
	_btn_script.pressed.connect(_open_script)
	_btn_state.pressed.connect(_edit_state)
	_btn_state_script.pressed.connect(_open_state_script)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func select() -> void:
	_label.add_theme_color_override('font_color', SELECTED_FONT_COLOR)
	clicked.emit(self)


func deselect() -> void:
	_label.add_theme_color_override('font_color', _dflt_font_color)


func show_add_to_core() -> void:
	_label.modulate.a = 0.5
	_menu_popup.set_item_disabled(
		_menu_popup.get_item_index(MenuOptions.ADD_TO_CORE), false
	)


func show_create_state_script() -> void:
	_btn_state_script.disabled = true
	_menu_popup.set_item_disabled(
		_menu_popup.get_item_index(MenuOptions.CREATE_STATE_SCRIPT), false
	)


func remove_create_state_script() -> void:
	_menu_popup.remove_item(
		_menu_popup.get_item_index(MenuOptions.CREATE_STATE_SCRIPT)
	)


func remove_menu_option(opt: int) -> void:
	_menu_popup.remove_item(_menu_popup.get_item_index(opt))


func add_button(btn: Button) -> void:
	buttons_container.add_child(btn)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func set_main_dock(value: Panel) -> void:
	main_dock = value
	_delete_dialog = main_dock.delete_dialog
	_delete_all_checkbox = _delete_dialog.find_child('CheckBox')


func set_is_main(value: bool) -> void:
	is_main = value
	_fav_icon.visible = value
	
	_menu_popup.set_item_disabled(
		_menu_popup.get_item_index(MenuOptions.SET_AS_MAIN), value
	)


func set_is_pc(value: bool) -> void:
	is_pc = value
	_fav_icon.visible = value

	_menu_popup.set_item_disabled(
		_menu_popup.get_item_index(MenuOptions.SET_AS_PC), value
	)


func set_is_on_start(value: bool) -> void:
	is_on_start = value
	_fav_icon.visible = value


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _create_menu() -> void:
	_menu_popup.clear()
	
	for option in _menu_cfg:
		if option:
			if option.has('types') and not type in option.types: continue
			
			_menu_popup.add_icon_item(
				option.icon,
				option.label,
				option.id
			)
		else:
			_menu_popup.add_separator()


func _check_click(event: InputEvent) -> void:
	var mouse_event: = event as InputEventMouseButton
	if mouse_event\
	and mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
		main_dock.ei.select_file(path)
		select()


func _menu_item_pressed(id: int) -> void:
	match id:
		MenuOptions.ADD_TO_CORE:
			_add_object_to_core()
		MenuOptions.SET_AS_MAIN:
			main_dock.set_main_scene(path)
			self.is_main = true
		MenuOptions.CREATE_STATE_SCRIPT:
			_create_state_script()
		MenuOptions.SET_AS_PC:
			main_dock.set_pc(name)
			self.is_pc = true
		MenuOptions.START_WITH_IT:
			var settings := PopochiuResources.get_settings()
			
			if name in settings.items_on_start:
				settings.items_on_start.erase(name)
			else:
				settings.items_on_start.append(name)
			
			PopochiuResources.save_settings(settings)
			(main_dock.ei as EditorInterface).get_inspector().refresh()
			
			self.is_on_start = name in settings.items_on_start
		MenuOptions.CREATE_PROP_SCRIPT:
			var prop_template := load(PROP_SCRIPT_TEMPLATE)
			var script_path := path + '/%s/Prop%s.gd' % [name, name]
			
			var prop: PopochiuProp =\
			main_dock.ei.get_edited_scene_root().get_node('Props/' + node_path)
			
			# Create the folder for the script
			if main_dock.dir.make_dir_recursive(script_path.get_base_dir()) != OK:
				push_error('[Popochiu] Could not create Prop folder for ' + str(name))
				return
			
			# Create the script
			if ResourceSaver.save(prop_template, script_path) != OK:
				push_error('[Popochiu] Could not create script: %s.gd' % name)
				return
			
			# Assign the created Script to the Prop, save the scene, and select
			# the node in the tree and the created file in the FileSystem dock
			var script := load(script_path)
			
			script.script_name = prop.script_name
			script.description = prop.description
			script.clickable = prop.clickable
			script.baseline = prop.baseline
			script.walk_to_point = prop.walk_to_point
			script.cursor = prop.cursor
			script.always_on_top = prop.always_on_top
			script.texture = prop.texture
			
			prop.set_script(script)
			
			main_dock.ei.save_scene()
			main_dock.ei.edit_node(prop)
			main_dock.ei.select_file(script_path)
			
			# Update this row properties and state
			path = script_path
			
			_btn_script.show()
			_menu_popup.set_item_disabled(
				_menu_popup.get_item_index(MenuOptions.CREATE_PROP_SCRIPT), true
			)
		MenuOptions.DELETE:
			_remove_object()


# Add this Object (Room, Character, InventoryItem, Dialog) to PopochiuData.cfg
# so it can be used by Popochiu.
func _add_object_to_core() -> void:
	var target_array := ''
	var resource: Resource
	
	if path.find('.tscn') > -1:
		resource = load(path.replace('.tscn', '.tres'))
	else:
		resource = load(path)
	
	match type:
		Constants.Types.ROOM:
			target_array = 'rooms'
		Constants.Types.CHARACTER:
			target_array = 'characters'
		Constants.Types.INVENTORY_ITEM:
			target_array = 'inventory_items'
		Constants.Types.DIALOG:
			target_array = 'dialogs'
		_:
			# TODO: Show an error message
			return
	
	if main_dock.add_resource_to_popochiu(target_array, resource) != OK:
		push_error("[Popochiu] Couldn't add Object to Popochiu: %s" % name)
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Add the object to its corresponding singleton
	PopochiuResources.update_autoloads(true)
	
	_label.modulate.a = 1.0
	
	_menu_popup.set_item_disabled(
		_menu_popup.get_item_index(MenuOptions.ADD_TO_CORE), true
	)


# Selecciona el archivo principal del objeto en el FileSystem y lo abre para que
# pueda ser editado.
func _open() -> void:
	main_dock.ei.select_file(path)
	
	if path.find('.tres') < 0:
		main_dock.ei.set_main_screen_editor('2D')
		main_dock.ei.open_scene_from_path(path)
	else:
		main_dock.ei.edit_resource(load(path))
	
	select()


func _open_script() -> void:
	var script_path := path
	
	if path.find('.tscn') > -1:
		# A room, character, inventory item, or prop
		script_path = path.replace('.tscn', '.gd')
	elif path.find('.tres') > -1:
		# A dialog
		script_path = path.replace('.tres', '.gd')
	elif path.find('.gd') == -1:
		return
	
	main_dock.ei.select_file(script_path)
	main_dock.ei.set_main_screen_editor('Script')
	main_dock.ei.edit_script(load(script_path))
	
	select()


func _edit_state() -> void:
	main_dock.ei.select_file(path.replace('.tscn', '.tres'))
	main_dock.ei.edit_resource(load(path.replace('.tscn', '.tres')))
	
	select()


func _open_state_script() -> void:
	var state := load(path.replace('.tscn', '.tres'))
	
	main_dock.ei.select_file(state.get_script().resource_path)
	main_dock.ei.set_main_screen_editor('Script')
	main_dock.ei.edit_resource(state.get_script())
	
	select()


# Shows a confirmation popup to ask the developer if the Popochiu object should
# be removed only from the core, or from the file system too.
func _remove_object() -> void:
	var location := 'Popochiu'
	
	# Verify if the object to delete is a Prop, a Hotspot or a Region.
	if type in Constants.ROOM_TYPES:
		# res://popochiu/rooms/???/props/??/ > [res:, popochiu, rooms, ???, props, ??]
		location = ("Room%s" % path.split('/', false)[3]).to_pascal_case()
	
	# Look into the Object's folder for audio files and AudioCues to show the
	# developer that those files will be removed too.
	var audio_files := _search_audio_files(
		main_dock.fs.get_filesystem_path(path.get_base_dir())
	)
	
	main_dock.show_confirmation(
		# Title
		'Remove %s from %s' % [name, location],
		# Body
		'This will remove the [b]%s[/b] resource in [b]%s[/b].' % [name, location] +\
		' Uses of this object in scripts will not work anymore.' +\
		' This action cannot be reversed. Continue?',
		# Additional confirmation
		'Want to delete the [b]%s[/b] folder too?' % path.get_base_dir() +\
		(
			' ([b]%d[/b] audio files will be deleted' % audio_files.size()\
			if audio_files.size() > 0\
			else ''
		) +\
		' (cannot be reversed))'\
		if path.get_extension()
		else ''
	)
	
	_delete_dialog.confirmed.connect(_remove_from_core)
	_delete_dialog.get_cancel_button().pressed.connect(_disconnect_popup)
	_delete_dialog.canceled.connect(_disconnect_popup)


func _search_audio_files(dir: EditorFileSystemDirectory) -> Array:
	var files := []
	
	for idx in dir.get_subdir_count():
		files.append_array(_search_audio_files(dir.get_subdir(idx)))
	
	for idx in dir.get_file_count():
		match dir.get_file_type(idx):
			'AudioStreamOggVorbis', 'AudioStreamMP3', 'AudioStreamWAV':
				files.append(dir.get_file_path(idx))
	
	return files


func _remove_from_core() -> void:
	# Delete the object from Popochiu ------------------------------------------
	match type:
		Constants.Types.ROOM:
			PopochiuResources.remove_autoload_obj(PopochiuResources.R_SNGL, name)
			
			PopochiuResources.erase_data_value('rooms', str(name))
		Constants.Types.CHARACTER:
			PopochiuResources.remove_autoload_obj(PopochiuResources.C_SNGL, name)
			
			PopochiuResources.erase_data_value('characters', str(name))
		Constants.Types.INVENTORY_ITEM:
			PopochiuResources.remove_autoload_obj(PopochiuResources.I_SNGL, name)
			
			PopochiuResources.erase_data_value('inventory_items', str(name))
		Constants.Types.DIALOG:
			PopochiuResources.remove_autoload_obj(PopochiuResources.D_SNGL, name)
			
			PopochiuResources.erase_data_value('dialogs', str(name))
		Constants.Types.PROP,\
		Constants.Types.HOTSPOT,\
		Constants.Types.REGION,\
		Constants.Types.WALKABLE_AREA:
			var opened_room: PopochiuRoom = main_dock.get_opened_room()
			if opened_room:
				match type:
					Constants.Types.PROP:
						opened_room.get_prop(str(name)).queue_free()
					Constants.Types.HOTSPOT:
						opened_room.get_hotspot(str(name)).queue_free()
					Constants.Types.REGION:
						opened_room.get_region(str(name)).queue_free()
					Constants.Types.WALKABLE_AREA:
						opened_room.get_walkable_area(str(name)).queue_free()
				
				main_dock.ei.save_scene()
			else:
				# TODO: open the Room' scene, delete the node and save the Room
				pass
			
			# TODO: If it is a non-interactable Object, just delete the node from the
			# scene, and maybe its sprite?
			# TODO: Remove explicit exclusion, it's ugly
			if path.is_empty():
				_disconnect_popup()
				return
	
	if _delete_all_checkbox.pressed:
		_delete_from_file_system()
	elif type in Constants.MAIN_TYPES:
		show_add_to_core()
	elif path.get_extension().is_empty():
		queue_free()
	
	_disconnect_popup()
	
	if main_dock.ei.get_edited_scene_root().script_name == name:
		return
	
	main_dock.ei.save_scene()


# Remove this object's directory (subfolders included) from the file system.
func _delete_from_file_system() -> void:
	var object_dir: EditorFileSystemDirectory = \
		main_dock.fs.get_filesystem_path(path.get_base_dir())
	
	# Remove files, sub folders and its files.
	assert(\
	_recursive_delete(object_dir) == OK,\
	'[Popochiu] Error in recursive elimination of %s' % path.get_base_dir()\
	)
	
	# Remove the object's folder
	assert(\
		main_dock.dir.remove_at(path.get_base_dir()) == OK,\
		'[Popochiu] Could not delete folder: %s' % path.get_base_dir()\
	)

	# Update the file system structure in the EditorFileSystem.
	main_dock.fs.scan()
	main_dock.fs.scan_sources()
	
	# Delete the element's row -------------------------------------------------
	queue_free()


# Elimina un directorio del sistema. Para que Godot pueda eliminar un directorio,
# este tiene que estar vacío, por eso este método elimina primero los archivos
# del directorio y cada uno de sus subdirectorios.
func _recursive_delete(dir: EditorFileSystemDirectory) -> int:
	if dir.get_subdir_count() > 0:
		for folder_idx in dir.get_subdir_count():
			var subfolder := dir.get_subdir(folder_idx)
			
			# Ver si hay más carpetas dentro de la carpeta, o borrar los archivos
			# dentro de esta para luego sí eliminar la carpeta
			_recursive_delete(subfolder)
			
			# Eliminar la carpeta
			var err: int = main_dock.dir.remove_at(subfolder.get_path())
			if err != OK:
				push_error('[Popochiu(err_code:%d)] Could not delete subdirectory %s' %\
				[err, subfolder.get_path()])
				return err
	
	return _delete_files(dir)


# Elimina los archivos dentro de un directorio. Primero se obtienen las rutas
# (path) a cada archivo y luego se van eliminando, uno a uno, y llamando a
# EditorFileSystem.update_file(path: String) para que, en caso de que sea un
# archivo importado, se elimine su .import.
func _delete_files(dir: EditorFileSystemDirectory) -> int:
	# Este arreglo guardará las rutas de los archivos a eliminar.
	var files_paths := []
	var deleted_audios := []
	
	for file_idx in dir.get_file_count():
		match dir.get_file_type(file_idx):
			'AudioStreamOggVorbis', 'AudioStreamMP3', 'AudioStreamWAV':
				deleted_audios.append(dir.get_file_path(file_idx))
			'Resource':
				var resource: Resource = load(dir.get_file_path(file_idx))
				if resource is AudioCue:
					deleted_audios.append(resource.audio.resource_path)
					
					# Delete the AudioCue in the PopochiuData.cfg
					for arr in ['mx_cues', 'sfx_cues', 'vo_cues', 'ui_cues']:
						var cues: Array = PopochiuResources.get_data_value(
							'audio', arr, []
						)
						if cues.has(resource.resource_path):
							cues.erase(resource.resource_path)
							assert(\
								PopochiuResources.set_data_value(
									'audio', arr, cues
								) == OK,\
								'[Popochiu] Could not save AudioManager after' +\
								' attempting to delete AudioCue during deletion of' +\
								' directory %s.' % dir.get_path()\
							)
							break
		
		files_paths.append(dir.get_file_path(file_idx))
	
	for fp in files_paths:
		# Así es como se hace en el código fuente del motor para que se eliminen
		# también los .import asociados a los archivos importados. ————————————
		var err: int = main_dock.dir.remove_at(fp)
		main_dock.fs.update_file(fp)
		# —————————————————————————————————————————————————————————————————————
		if err != OK:
			push_error('[Popochiu(err_code:%d)] Could not delete file %s' %\
			[err, fp])
			return err
	
	# Eliminar las filas en la pestaña de Audio de los archivos de audio y los
	# AudioCue eliminados.
	if not deleted_audios.is_empty():
		main_dock.get_audio_tab().delete_rows(deleted_audios)
	
	return OK


# Se desconecta de las señales del popup utilizado para configurar la eliminación.
func _disconnect_popup() -> void:
	_delete_dialog.confirmed.disconnect(_remove_from_core)
	_delete_dialog.get_cancel_button().pressed.disconnect(_disconnect_popup)
	_delete_dialog.canceled.disconnect(_disconnect_popup)


func _create_state_script() -> void:
	var template: Script = null
	
	match type:
		Constants.Types.ROOM:
			template = load(ROOM_STATE_TEMPLATE)
		Constants.Types.CHARACTER:
			template = load(CHARACTER_STATE_TEMPLATE)
		Constants.Types.INVENTORY_ITEM:
			template = load(INVENTORY_ITEM_STATE_TEMPLATE)
	
	var script_path := path.replace('.tscn', 'State.gd')
	
	# Create the folder for the script
	if main_dock.dir.make_dir_recursive(script_path.get_base_dir()) != OK:
		push_error('[Popochiu] Could not create state script for ' + str(name))
		return
	
	# Create the script
	if ResourceSaver.save(template, script_path) != OK:
		push_error('[Popochiu] Could not create script: %s.gd' % name)
		return
	
	# Assign the created Script to the object's state resource
	var state_resource := load(path.replace('tscn', 'tres'))
	state_resource.set_script(load(script_path))
	state_resource.script_name = name
	state_resource.scene = path
	
	if ResourceSaver.save(state_resource, state_resource.resource_path) != OK:
		push_error('[Popochiu] Could not create script: %s.gd' % name)
		return
	
	# Disable the context menu option and enable the button to open the state
	# script
	_menu_popup.set_item_disabled(
		_menu_popup.get_item_index(MenuOptions.CREATE_STATE_SCRIPT), true
	)
	_btn_state_script.disabled = false
	
	# Select and open the created script
	_open_state_script()
