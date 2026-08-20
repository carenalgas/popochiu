class_name PopochiuHotspotRow
extends PopochiuRoomObjRow
# Row for Hotspots in the Room tab. Config-only subclass.
#
# Ref: #558

func _init(dock: PopochiuTreeDock) -> void:
	super(dock, PopochiuResources.Types.HOTSPOT)
	_title = "Hotspots"
	_icon = preload("res://addons/popochiu/icons/hotspot.png")
	_create_text = "Create hotspot"
	_popup = PopochiuEditorHelper.CREATE_HOTSPOT
	_method = "get_hotspots"
	_type_class = PopochiuHotspot
	_parent_name = "Hotspots"
	_getter = "get_hotspot"