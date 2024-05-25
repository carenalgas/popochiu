@tool
class_name Gizmo2D
extends RefCounted

# Gizmo types
enum {
	GIZMO_POS, # square marker that represents (x,y) coordinates
	GIZMO_HPOS, # vertical line that represents a horizontal coordinate
	GIZMO_VPOS # horizontal line that represents a vertical coordinate
}

# Public vars
# Convienence accessors
var target_node: Node2D:
	set = set_target_node,
	get = get_target_node
var target_property: String:
	set = set_target_property,
	get = get_target_property
var position:
	get = get_position
# Behavior flags
var show_connector: bool = true # Show gizmo-to-node connectors
var show_outlines: bool = true
var show_target_name: bool = true # Show target node name
var visible: bool = true # Gizmo visibility

# Private vars
# Context
var _type: int
var _target_node: Node2D
var _target_property: String
# Appearance
var _size: Vector2 # Gizmo width and height
var _color: Color # Gizmo color
var _label: String # A label to be painted near the Gizmo
var _font: Font # Label font
var _font_size: int # Label font size
# State
var _handle: Rect2 # Gizmo handle
var _current_position: Vector2 # The position the gizmo is representing in every moment
var _current_color: Color
var _is_grabbed: bool = false # Gizmo is moving
var _grab_center_pos: Vector2 # Starting center position when grabbing
var _grab_mouse_pos: Vector2 # Starting mouse position when grabbing


#region Virtual ####################################################################################

func _init(
	node: Node,
	property: String,
	label: String,
	type: int,
):
	_target_node = node
	_target_property = property
	_type = type
	_label = label

	set_theme(
		Color.AQUA,
		24,
		EditorInterface.get_editor_theme().default_font,
		EditorInterface.get_editor_theme().default_font_size
	)
	
	_current_color = _color


#endregion

#region SetGet #####################################################################################

func set_theme(
	color: Color,
	size: int,
	font: Font,
	font_size: int
):
	_color = color
	_size = Vector2(size, size)
	_font = font
	_font_size = font_size

func set_target_node(node: Node2D):
	_target_node = node

func get_target_node() -> Node2D:
	return _target_node

func set_target_property(property: String):
	_target_property = property

func get_target_property() -> String:
	if _target_property:
		return _target_property
	return ""


#endregion

#region Private ####################################################################################

func _draw_outlines(viewport: Control):
	viewport.draw_rect(
		_handle,
		Color.BLACK, false, 4
	)

	viewport.draw_string_outline(
		_font,
		_handle.position + Vector2(0, _size.y + 2 + _font.get_ascent(_font_size)),
		_label, HORIZONTAL_ALIGNMENT_CENTER,
		- 1,
		_font_size,
		6,
		Color.BLACK
	)

	if show_target_name:
		viewport.draw_string_outline(
			_font,
			_handle.position + Vector2(0, -_font.get_descent(_font_size)),
			_target_node.name,
			HORIZONTAL_ALIGNMENT_CENTER,
			- 1,
			_font_size,
			6,
			Color.BLACK
		)

func _draw_gizmo(viewport: Control):

	# Draw the handle (on top of the line, if it's present)
	viewport.draw_rect(
		_handle,
		_current_color
	)

	# Draw gizmo-to-node connector, if active
	if show_connector:
		viewport.draw_dashed_line(
			(_target_node.get_viewport_transform() * _target_node.get_global_transform()).origin,
			_handle.get_center(),
			_current_color.darkened(0.2),
			2,
			4
		)
		viewport.draw_circle(
			_handle.get_center(),
			3,
			_current_color.darkened(0.2)
		)

	# Draw the label, if it's set and non empty
	if _label:
		viewport.draw_string(
			_font,
			_handle.position + Vector2(0, _size.y + 2 + _font.get_ascent(_font_size)),
			_label, HORIZONTAL_ALIGNMENT_CENTER,
			- 1,
			_font_size,
			_current_color
		)

	if show_target_name:
		viewport.draw_string(
			_font,
			_handle.position + Vector2(0, -_font.get_descent(_font_size)),
			_target_node.name,
			HORIZONTAL_ALIGNMENT_CENTER,
			- 1,
			_font_size,
			_current_color
		)

func _can_draw():
	return (visible and _target_node != null and _target_node.is_visible_in_tree())


#endregion

#region Public #####################################################################################

func draw(viewport: Control, coord: Variant) -> void:
	# Handmade coordinates type overloading
	if not (coord is Vector2 or coord is int):
		return
	# Check if the gizmo can be drawn
	if not _can_draw():
		return
	
	# Coordinates normalization (to vector) for horizontal or vertical gizmos
	# Both axis are set to the same value, then ignore one or the other
	# depending on the gizmo type
	if coord is int:
		coord = Vector2(coord, coord)

	# Caculate the GLOBAL coordinates of the center of the square handle
	# This only takes into account the node offset discarding its transform basis
	# (representing rotation, skew and scale) then it applies the viewport transform
	# to take into account the zoom level
	var center = _target_node.get_viewport_transform() * (_target_node.get_global_transform().origin + Vector2(coord))

	# Set handle color
	_current_color = _color
	# Highlight handle if held by the mouse click
	if _is_grabbed:
		_current_color = _color.lightened(0.5)

	# Draw an horizontal or vertical line if the gizmo is one-dimensional
	match _type:
		GIZMO_VPOS:
			var viewport_width = EditorInterface.get_editor_viewport_2d().size.x
			center.x = viewport_width / 2
			viewport.draw_line(
				Vector2(0, center.y),
				Vector2(viewport_width, center.y),
				_current_color,
				2
			)
		GIZMO_HPOS:
			var viewport_height = EditorInterface.get_editor_viewport_2d().size.y
			center.y = viewport_height / 2
			viewport.draw_line(
				Vector2(center.x, 0),
				Vector2(center.x, viewport_height),
				_current_color,
				2
			)
	
	# Initialize the handle in the right position
	_handle = Rect2(center - _size / 2, _size)

	if show_outlines:
		_draw_outlines(viewport)

	_draw_gizmo(viewport)

func drag_to(pos: Vector2):
	# Distance between the mouse position and the gizmo center
	var d = _grab_center_pos - _grab_mouse_pos
	# Gizmo center postion in global coordinates
	var current_gizmo_pos = pos + d
	# Distance between gizmo center position in 2D world node coordinates and
	# node position	ignoring its transform basis (representing rotation, skew and scale)
	_current_position = _target_node.get_viewport_transform().affine_inverse() * current_gizmo_pos - (target_node.get_global_transform().origin)

func release():
	_is_grabbed = false

func grab(pos: Vector2):
	_is_grabbed = true
	_grab_mouse_pos = pos
	_grab_center_pos = _handle.get_center()

func cancel():
	_is_grabbed = false

func has_point(pos: Vector2):
	return visible and _handle.abs().has_point(pos)

func get_position():
	match _type:
		GIZMO_POS:
			return _current_position
		GIZMO_HPOS:
			return _current_position.x
		GIZMO_VPOS:
			return _current_position.y


#endregion
