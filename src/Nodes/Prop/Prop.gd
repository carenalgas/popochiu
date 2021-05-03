tool
class_name Prop
extends Clickable
# Elementos visuales para las habitaciones. Pueden tener interacción.
# Ej: las imágenes de fondo y primer plano, un objeto que se puede agarrar...

export var texture: Texture setget _set_texture


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func on_interact() -> void:
	pass


func on_look() -> void:
	pass


func on_item_used(item: Item) -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _set_texture(value: Texture) -> void:
	texture = value
	$Sprite.texture = value
