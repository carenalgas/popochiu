tool
class_name PopochiuHotspot, 'res://addons/Popochiu/icons/hotspot.png'
extends 'res://addons/Popochiu/Engine/Objects/Clickable/PopochiuClickable.gd'
# Permite crear áreas con las que se puede interactuar.
# Ej: El cielo, algo que haga parte de la imagen de fondo.


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func on_interact() -> void:
	.on_interact()


func on_look() -> void:
	.on_look()


func on_item_used(item: InventoryItem) -> void:
	.on_item_used(item)
