tool
class_name PopochiuProp, 'res://addons/Popochiu/icons/prop.png'
extends 'res://addons/Popochiu/Engine/Objects/Clickable/PopochiuClickable.gd'
# Visual elements in the Room. Can have interaction.
# E.g. Background, foreground, a table, a cup, etc.
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

export var texture: Texture setget _set_texture
#export var parallax_depth := 1.0 setget _set_parallax_depth
#export var parallax_alignment := Vector2.ZERO

onready var _sprite: Sprite = $Sprite


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	add_to_group('props')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _set_texture(value: Texture) -> void:
	texture = value
	$Sprite.texture = value


#func _set_parallax_depth(value: float) -> void:
#	parallax_depth = value
##	$ParallaxLayer.motion_scale = Vector2.ONE * value
#	property_list_changed_notify()
