extends TextureButton
# warning-ignore-all:return_value_discarded

const CURSOR := preload('res://addons/popochiu/engine/cursor/cursor.gd')
#const CONSTANTS := preload('res://addons/popochiu/popochiu_resources.gd')

#@export var cursor: CONSTANTS.CursorType = CONSTANTS.CursorType.USE
@export var cursor: CURSOR.Type = CURSOR.Type.USE
@export var description := '' : get = get_description
@export var script_name := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	pressed.connect(on_pressed)
	mouse_entered.connect(on_mouse_entered)
	mouse_exited.connect(on_mouse_exited)


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
