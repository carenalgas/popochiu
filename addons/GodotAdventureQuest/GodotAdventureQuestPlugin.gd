tool
extends EditorPlugin

var gaq_dock: Control


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _enter_tree() -> void:
	gaq_dock = preload("res://addons/GodotAdventureQuest/GAQMainDock/GAQMainDock.tscn").instance()
	gaq_dock.editor_interface = get_editor_interface()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, gaq_dock)


func _exit_tree() -> void:
	remove_control_from_docks(gaq_dock)
