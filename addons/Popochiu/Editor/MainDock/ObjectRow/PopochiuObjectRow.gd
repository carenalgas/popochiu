tool
class_name PopochiuObjectRow
extends HBoxContainer

signal delete_pressed(type)
signal open_pressed(path)

var type := ''
var path := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready() -> void:
	$Label.text = name
	
	$Delete.connect('pressed', self, '_delete')
	$Open.connect('pressed', self, '_open')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _delete() -> void:
	emit_signal('delete_pressed', type)


func _open() -> void:
	emit_signal('open_pressed', path)
