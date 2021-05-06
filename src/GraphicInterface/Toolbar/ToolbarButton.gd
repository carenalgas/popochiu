class_name ToolbarButton
extends TextureButton

export var description := '' setget ,get_description
export var script_name := ''
export(Cursor.Type) var cursor

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	connect('pressed', self, 'on_pressed')
	connect('mouse_entered', self, 'on_mouse_entered')
	connect('mouse_exited', self, 'on_mouse_exited')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func on_pressed() -> void:
	pass


func on_mouse_entered() -> void:
	Cursor.set_cursor(cursor)
	G.show_info(self.description)


func on_mouse_exited() -> void:
	Cursor.set_cursor()
	G.show_info()


func get_description() -> String:
	return description
