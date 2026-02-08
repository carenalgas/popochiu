# @popochiu-docs-category game-user-interface
class_name PopochiuCursor
extends CanvasLayer

## Legacy cursor [Type] enum kept for compatibility with older code and
## creation popups. Values represent named cursor states used by the UI.
# TODO: Deprecate this? I'll leave it here while we merge the refactor for the
# 		creation popups because in those the Cursor.Type enum is used.
enum Type {
	NONE,
	ACTIVE,
	DOWN,
	IDLE,
	LEFT,
	LOOK,
	RIGHT,
	SEARCH,
	TALK,
	UP,
	USE,
	WAIT,
}

## When [code]true[/code], cursor positions are snapped to integer pixels
## (using [Vector2i]) to produce a pixel-perfect cursor. When [code]false[/code],
## cursor positions use floating-point [Vector2] coordinates allowing sub-pixel positioning.
@export var is_pixel_perfect := false

## When [code]true[/code], methods that respect blocking (for example
## [method show_cursor] and [method set_secondary_cursor_texture]) will ignore
## requests unless their `ignore_block` parameter is [code]true[/code].
var is_blocked := false

## The primary cursor node ([AnimatedSprite2D]) used for rendering cursor
## animations and determining main cursor size and offset.
@onready var main_cursor: AnimatedSprite2D = $MainCursor

## The secondary cursor node ([Sprite2D]) used for temporary textures such as
## item cursors or overlays. Its visibility and texture are controlled at runtime.
@onready var secondary_cursor: Sprite2D = $SecondaryCursor


#region Godot ######################################################################################
func _init() -> void:
	Engine.register_singleton(&"Cursor", self)


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Connect to autoload signals
	PopochiuUtils.e.ready.connect(show_cursor)


func _process(delta):
	var texture_size := (main_cursor.sprite_frames.get_frame_texture(
		main_cursor.animation,
		main_cursor.frame
	) as Texture2D).get_size()
	
	var mouse_position: Vector2 = main_cursor.get_global_mouse_position()
	
	if is_pixel_perfect:
		# Thanks to @whyshchuck
		main_cursor.position = Vector2i(mouse_position)
		secondary_cursor.position = Vector2i(mouse_position)
	else:
		main_cursor.position = mouse_position
		secondary_cursor.position = mouse_position
	
	if main_cursor.position.x < 1.0:
		main_cursor.position.x = 1.0
	elif main_cursor.position.x > PopochiuUtils.e.width - 2.0:
		main_cursor.position.x = PopochiuUtils.e.width - 2.0
	
	if main_cursor.position.y < 1.0:
		main_cursor.position.y = 1.0
	elif main_cursor.position.y > PopochiuUtils.e.height - 2.0:
		main_cursor.position.y = PopochiuUtils.e.height - 2.0


#endregion

#region Public #####################################################################################
## Shows the cursor using [param anim_name]. If the cursor is blocked the call is ignored, unless
## [param ignore_block] is [code]true[/code]. If the animation does not exist, an error is logged.
func show_cursor(anim_name := "normal", ignore_block := false) -> void:
	if not ignore_block and is_blocked: return
	
	if (
		not anim_name.is_empty()
		and not main_cursor.sprite_frames.has_animation(anim_name)
	):
		PopochiuUtils.print_error("Cursor has no animation: %s" % anim_name)
		return
	
	main_cursor.play(anim_name)
	main_cursor.show()
	secondary_cursor.hide()


## Sets the secondary cursor texture to [param texture]. If the cursor is blocked the call is ignored, unless
## [param ignore_block] is [code]true[/code].
##
## When [member PopochiuUtils.e.settings.scale_gui] (**experimental**) is enabled, the texture is scaled relative to the main cursor height.
func set_secondary_cursor_texture(texture: Texture2D, ignore_block := false) -> void:
	if not ignore_block and is_blocked: return
	
	secondary_cursor.texture = texture
	
	if PopochiuUtils.e.settings.scale_gui:
		# Scale the cursor based the relation of the texture size compared to the main cursor
		# texture size
		secondary_cursor.scale = Vector2.ONE * ceil(
			float(texture.get_height()) / float(get_cursor_height())
		)
	
	secondary_cursor.show()


## Removes the secondary cursor texture.[br]
## Restores default scale when GUI scaling (**experimental**) is enabled.
func remove_secondary_cursor_texture() -> void:
	secondary_cursor.texture = null
	
	if PopochiuUtils.e.settings.scale_gui:
		secondary_cursor.scale = PopochiuUtils.e.scale
	
	secondary_cursor.hide()


## Sets visibility of both main and secondary cursors to [param is_visible].
func toggle_visibility(is_visible: bool) -> void:
	main_cursor.visible = is_visible
	secondary_cursor.visible = is_visible


## Causes the cursor to enter a blocked state. While blocked, cursor update calls that respect blocking
## (for example `show_cursor` and `set_secondary_cursor_texture`) are ignored unless their `ignore_block`
## parameter is used.
func block() -> void:
	is_blocked = true


## Clears the cursor blocked state, allowing cursor methods to update the cursor again. This does not
## change the current cursor animation or texture.
func unblock() -> void:
	is_blocked = false


## Scale both main and secondary cursors by a [param factor] ([Vector2]).
func scale_cursor(factor: Vector2) -> void:
	secondary_cursor.scale = factor
	main_cursor.scale = factor


## Returns the current cursor position as a [Vector2].
func get_position() -> Vector2:
	return secondary_cursor.position


## Replaces the main cursor sprite frames (and offset) with those from [param new_node]
## ([AnimatedSprite2D]).
func replace_frames(new_node: AnimatedSprite2D) -> void:
	main_cursor.sprite_frames = new_node.sprite_frames
	main_cursor.centered = new_node.centered
	main_cursor.offset = new_node.offset


## Hides the main cursor.
func hide_main_cursor() -> void:
	main_cursor.hide()


## Shows the main cursor.
func show_main_cursor() -> void:
	main_cursor.show()


## Hides the secondary cursor.
func hide_secondary_cursor() -> void:
	secondary_cursor.hide()


## Shows the secondary cursor.
func show_secondary_cursor() -> void:
	secondary_cursor.show()


## Returns the snake_case name of the cursor [Type] at index [param idx] as a [String].
func get_type_name(idx: int) -> String:
	return Type.keys()[idx].to_snake_case()


## Returns the current cursor height in pixels as an [int]. Uses the visible cursor's texture
## height. If the main cursor is visible uses its current frame height, otherwise the secondary
## cursor texture is used.
func get_cursor_height() -> int:
	var height := 0
	
	if main_cursor.visible:
		height = main_cursor.sprite_frames.get_frame_texture(main_cursor.animation, 0).get_height()
	elif secondary_cursor.visible:
		height = secondary_cursor.texture.get_height()
	
	return height


#endregion
