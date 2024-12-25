@tool
extends Panel

signal move_folders_pressed

@onready var tab_container: TabContainer = %TabContainer
@onready var tab_main: VBoxContainer = %Main
@onready var tab_room: VBoxContainer = %Room
@onready var tab_audio: VBoxContainer = %Audio
@onready var tab_gui: VBoxContainer = %GUI
# ---- FOOTER --------------------------------------------------------------------------------------
@onready var version: Label = %Version
@onready var btn_setup: Button = %BtnSetup
@onready var btn_docs: Button = %BtnDocs


#region Godot ######################################################################################
func _ready() -> void:
	version.text = "v" + PopochiuResources.get_version()
	btn_setup.icon = get_theme_icon("Edit", "EditorIcons")
	btn_docs.icon = get_theme_icon("HelpSearch", "EditorIcons")
	
	# Set the Main tab selected by default
	tab_container.current_tab = 0
	
	# Hide the GUI tab while we decide how it will work based on devs feedback
	tab_container.set_tab_hidden(tab_gui.get_index(), true)
	
	# Connect to children's signals
	tab_container.tab_changed.connect(_on_tab_changed)
	btn_setup.pressed.connect(open_setup)
	btn_docs.pressed.connect(OS.shell_open.bind(PopochiuResources.DOCUMENTATION))
	
	# Connect to parent signals
	get_tree().node_added.connect(_check_node)


#endregion

#region Public #####################################################################################
func fill_data() -> void:
	tab_main.fill_data()
	tab_audio.fill_data()


func scene_changed(scene_root: Node) -> void:
	if not is_instance_valid(tab_room): return
	tab_room.scene_changed(scene_root)
	
	# TODO: Uncomment these lines when working on the GUI tab again
	#if not is_instance_valid(tab_gui): return
	#tab_gui.on_scene_changed(scene_root)
	
	if (
		not scene_root
		or (
			not scene_root is PopochiuRoom
			# TODO: Uncomment this line when working on the GUI tab again
			#and not scene_root.scene_file_path == PopochiuResources.GUI_GAME_SCENE
		)
	):
		# Open the Popochiu Main tab if the opened scene in the Editor2D is not a PopochiuRoom nor
		# the GUI scene
		tab_container.current_tab = 0


func scene_closed(filepath: String) -> void:
	if not is_instance_valid(tab_room): return
	tab_room.scene_closed(filepath)
	check_open_scenes()


func search_audio_files() -> void:
	if not is_instance_valid(tab_audio): return
	
	tab_audio.search_audio_files()


func open_setup() -> void:
	PopochiuEditorHelper.show_setup()


## If there are no other opened scenes in the Editor, this function connects to
## [signal EditorSelection.selection_changed] in order to make sure the Popochiu dock behaves as
## expected when the [signal EditorPlugin.scene_changed] signal is not emitted.
func check_open_scenes() -> void:
	# Fixes #273: Since Godot is not triggering the EditorPlugin.scene_changed signal when opening a
	# scene when no other scenes are opened, listen to the EditorSelection.selection_changed signal
	await get_tree().process_frame
	if EditorInterface.get_open_scenes().is_empty():
		EditorInterface.get_selection().selection_changed.connect(_on_editor_selection_changed)


#endregion

#region Private ####################################################################################
func _on_tab_changed(tab: int) -> void:
	if tab == tab_main.get_index():
		tab_main.check_data()
	
	if tab == tab_gui.get_index():
		tab_gui.open_gui_scene()


func _check_node(node: Node) -> void:
	if node is PopochiuCharacter and node.get_parent() is Node2D:
		# The node is a PopochiuCharacter in a room
		node.set_name.call_deferred("Character%s *" % node.script_name)


func _on_editor_selection_changed() -> void:
	if EditorInterface.get_edited_scene_root():
		EditorInterface.get_selection().selection_changed.disconnect(_on_editor_selection_changed)
		scene_changed(EditorInterface.get_edited_scene_root())


#endregion
