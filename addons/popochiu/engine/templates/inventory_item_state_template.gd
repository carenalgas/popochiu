# @popochiu-docs-ignore-class
extends PopochiuInventoryItemData
# Add variables here that should be saved and loaded with the game state.
# By default only Godot's built-in types are automatically saved/loaded.
# Use `save_custom` and `load_custom` to handle custom types.
# Note: `script_name` and `scene` variables inherited from the base class are not saved.


#region Virtual ####################################################################################
# Return a Dictionary of custom data to save for this PopochiuInventoryItem.
# The Dictionary must contain only JSON-supported types: bool, int, float, String.
func _on_save() -> Dictionary:
	return {}


# Called when the game is loaded.
# The `data` Dictionary should match the structure returned by `_on_save()`.
func _on_load(data: Dictionary) -> void:
	prints(data)


#endregion
