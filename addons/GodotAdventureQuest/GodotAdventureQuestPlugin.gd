tool
extends EditorPlugin

var gaq_dock: Control

var _editor_interface: EditorInterface
var _file_system: EditorFileSystem


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _enter_tree() -> void:
	_editor_interface = get_editor_interface()
	_file_system = _editor_interface.get_resource_filesystem()

	gaq_dock = preload("res://addons/GodotAdventureQuest/MainDock/MainDock.tscn").instance()
	gaq_dock.ei = _editor_interface
	gaq_dock.fs = _file_system

	add_control_to_dock(DOCK_SLOT_RIGHT_UR, gaq_dock)
	
	# Agregar los tipos de Resource del plugin
	add_custom_type('> GAQRoom', 'Resource', preload('res://src/Helpers/GAQRoom.gd'), null)
	add_custom_type('> GAQCharacter', 'Resource', preload('res://src/Helpers/GAQCharacter.gd'), null)
	
#	_file_system.connect("filesystem_changed", self, "_on_filesystem_changed")
	
	# Llenar las listas de habitaciones, personajes, objetos de inventario y
	# árboles de diálogo.
	yield(get_tree().create_timer(1.0), 'timeout')
	gaq_dock.fill_data()


func _exit_tree() -> void:
	remove_control_from_docks(gaq_dock)


func _on_filesystem_changed() -> void:
	prints('Cambiao')
#	gaq_dock.fill_data()
