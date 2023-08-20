@icon('res://addons/popochiu/icons/inventory_item.png')
class_name PopochiuInventoryItemData
extends Resource

@export var script_name := ''
@export_file("*.tscn") var scene := ''


#region Virtual ####################################################################################
func _on_save() -> Dictionary:
	return {}


func _on_load(_data: Dictionary) -> void:
	pass


#endregion

#region Public #####################################################################################
# Use this to save custom data for this PopochiuCharacter when saving the game.
# The Dictionary must contain only JSON supported types: bool, int, float, String.
func on_save() -> Dictionary:
	return _on_save()


# Called when the game is loaded.
# This Dictionary should has the same structure you defined for the returned
# one in on_save().
func on_load(data: Dictionary) -> void:
	_on_load(data)


#endregion
