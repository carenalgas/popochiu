class_name PopochiuGUIInfo
extends Resource

enum GUITargetRes {
	LOW_RESOLUTION,
	HIGH_RESOLUTION,
}

@export var title := ""
@export_multiline var description := ""
@export var icon: Texture
@export var target_resolution: GUITargetRes
