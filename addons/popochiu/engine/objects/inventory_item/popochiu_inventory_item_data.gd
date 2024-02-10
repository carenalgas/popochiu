@icon('res://addons/popochiu/icons/inventory_item.png')
class_name PopochiuInventoryItemData
extends Resource
## This class is used to store information when saving and loading the game. It also ensures that
## the data remains throughout the game's execution.

## The identifier of the object used in scripts.
@export var script_name := ''
## The path to the scene file to be used when adding the character to the game during runtime.
@export_file("*.tscn") var scene := ''


#region Virtual ####################################################################################
## Called when the game is saved.
## [i]Virtual[/i].
func _on_save() -> Dictionary:
	return {}


## Called when the game is loaded. The structure of [param data] is the same returned by
## [method _on_save].
## [i]Virtual[/i].
func _on_load(_data: Dictionary) -> void:
	pass


#endregion

#region Public #####################################################################################
## Use this to store custom data when saving the game. The returned [Dictionary] must contain only
## JSON supported types: [bool], [int], [float], [String].
func on_save() -> Dictionary:
	return _on_save()


## Called when the game is loaded. [param data] will have the same structure you defined for the
## returned [Dictionary] by [method _on_save].
func on_load(data: Dictionary) -> void:
	_on_load(data)


#endregion
