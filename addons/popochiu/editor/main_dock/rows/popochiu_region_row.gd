class_name PopochiuRegionRow
extends PopochiuRoomObjRow
# Row for Regions in the Room tab. Config-only subclass.
#
# Ref: #558

func _init(dock: PopochiuTreeDock) -> void:
	super(dock, PopochiuResources.Types.REGION)
	_title = "Regions"
	_icon = preload("res://addons/popochiu/icons/region.png")
	_create_text = "Create regions"
	_popup = PopochiuEditorHelper.CREATE_REGION
	_method = "get_regions"
	_type_class = PopochiuRegion
	_parent_name = "Regions"
	_getter = "get_region"