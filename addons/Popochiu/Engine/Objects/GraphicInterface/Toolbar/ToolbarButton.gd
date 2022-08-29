extends TextureButton
# warning-ignore-all:return_value_discarded

#const CURSOR_TYPE := preload('res://addons/Popochiu/Engine/Cursor/Cursor.gd').Type
#const Constants := preload('res://addons/Popochiu/PopochiuResources.gd')

#export(Constants.CursorType) var cursor := Constants.CursorType.USE
export var description := '' setget ,get_description
export var script_name := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	connect('pressed', self, 'on_pressed')
	connect('mouse_entered', self, 'on_mouse_entered')
	connect('mouse_exited', self, 'on_mouse_exited')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func on_pressed() -> void:
	pass


func on_mouse_entered() -> void:
	Cursor.set_cursor(10)
	G.show_info(self.description)


func on_mouse_exited() -> void:
	Cursor.set_cursor()
	G.show_info()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func get_description() -> String:
	return description
