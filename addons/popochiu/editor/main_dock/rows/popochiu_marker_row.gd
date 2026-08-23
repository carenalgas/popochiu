class_name PopochiuMarkerRow
extends PopochiuRoomObjRow
# Row for Markers in the Room tab. Config-only subclass.
#
# Ref: #558

func _init(dock: PopochiuTreeDock) -> void:
	super(dock, PopochiuResources.Types.MARKER)
	_title = "Markers"
	_icon = preload("res://addons/popochiu/icons/marker.svg")
	_create_text = "Create marker"
	_popup = PopochiuEditorHelper.CREATE_MARKER
	_method = "get_markers"
	_type_class = Marker2D
	_parent_name = "Markers"
	_getter = "get_marker"