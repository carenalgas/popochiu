class_name PopochiuPropRow
extends PopochiuRoomObjRow
# Row for Props in the Room tab. Config-only subclass.
#
# Ref: #558

func _init(dock: PopochiuTreeDock) -> void:
	super(dock, PopochiuResources.Types.PROP)
	_title = "Props"
	_icon = preload("res://addons/popochiu/icons/prop.svg")
	_create_text = "Create prop"
	_popup = PopochiuEditorHelper.CREATE_PROP
	_method = "get_props"
	_type_class = PopochiuProp
	_parent_name = "Props"
	_getter = "get_prop"