# @popochiu-docs-category game-objects-data-managers
@icon('res://addons/popochiu/icons/inventory_item.png')
class_name PopochiuInventoryItemData
extends Resource
## Stores persistent data for an inventory item across save/load operations.
##
## This resource maintains state throughout gameplay and handles serialization when saving and
## loading the game.

## The identifier of the object used in scripts.
@export var script_name := ''
## The path to the scene file to be used when adding the character to the game during runtime.
@export_file("*.tscn") var scene := ''


#region Virtual ####################################################################################
## Called when the game is saved.[br]
## Implement this to persist custom properties that you added to this resource. Should return
## a [Dictionary] containing the data to be saved.[br]
## The returned [Dictionary] must contain only JSON-supported types:
## [bool], [int], [float], [String].
func _on_save() -> Dictionary:
	return {}


## Called when the game is loaded. The structure of [param data] matches that returned by
## [method _on_save].[br]
## Implement this to restore the custom properties you persisted in [_on_save].
func _on_load(_data: Dictionary) -> void:
	pass


#endregion

#region Public #####################################################################################
# @popochiu-docs-ignore
#
## Called by the engine before saving the game.
func on_save() -> Dictionary:
	return _on_save()


# @popochiu-docs-ignore
#
## Called by the engine after loading a saved game.
func on_load(data: Dictionary) -> void:
	_on_load(data)


#endregion
