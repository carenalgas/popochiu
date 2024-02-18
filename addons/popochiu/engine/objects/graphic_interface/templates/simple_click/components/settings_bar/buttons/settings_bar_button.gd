extends TextureButton
# warning-ignore-all:return_value_discarded

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
	G.show_hover_text(self.description)


func on_mouse_exited() -> void:
	G.show_hover_text()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func get_description() -> String:
	return description
