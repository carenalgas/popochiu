tool
class_name Clickable
extends Area2D
# Permite definir colisiones que reaccionan a los eventos de clic y entrada y
# salida del cursor.

# TODO: Hacer la lógica para el uso de objetos de inventario sobre este nodo

signal interacted
signal looked

export var description := ''
export var baseline := 0
export var clickable := true
export var walk_to_point: Vector2
export var look_at_point: Vector2
export(Cursor.Type) var cursor
export var script_name := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready():
	if clickable:
		connect('mouse_entered', self, '_toggle_description', [true])
		connect('mouse_exited', self, '_toggle_description', [false])
	
	set_process_unhandled_input(false)


func _unhandled_input(event):
	var mouse_event: = event as InputEventMouseButton 
	if mouse_event and mouse_event.pressed:
		if event.is_action_pressed('interact'):
			# TODO: Verificar si hay un elemento de inventario seleccionado
			get_tree().set_input_as_handled()
			Data.clicked = self
			if I.active:
				on_item_used(I.active)
			else:
				on_interact()
		elif event.is_action_pressed('look'):
			if not I.active:
				on_look()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func on_interact() -> void:
	yield(G.display('No hay na\' pa\' hacer con esta mondá'), 'completed')
	G.done()


func on_look() -> void:
	yield(G.display('No es nada...'), 'completed')
	G.done()


func on_item_used(item: Item) -> void:
	pass



# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _toggle_description(display: bool) -> void:
	set_process_unhandled_input(display)
	Cursor.set_cursor(cursor if display else null)
	if display:
		if not I.active:
			G.show_info(description)
		else:
			G.show_info('Usar %s en %s' % [I.active.description, description])
	else:
		G.show_info()
