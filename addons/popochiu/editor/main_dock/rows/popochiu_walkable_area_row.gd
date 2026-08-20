class_name PopochiuWalkableAreaRow
extends PopochiuRoomObjRow
# Row for Walkable areas in the Room tab. Config-only subclass.
#
# Ref: #558

func _init(dock: PopochiuTreeDock) -> void:
	super(dock, PopochiuResources.Types.WALKABLE_AREA)
	_title = "Walkable areas"
	_icon = preload("res://addons/popochiu/icons/walkable_area.png")
	_create_text = "Create walkable area"
	_popup = PopochiuEditorHelper.CREATE_WALKABLE_AREA
	_method = "get_walkable_areas"
	_type_class = PopochiuWalkableArea
	_parent_name = "WalkableAreas"
	_getter = "get_walkable_area"