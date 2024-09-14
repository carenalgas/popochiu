@tool
extends PopochiuPopup


#region Virtual ####################################################################################
## Called when the popup is opened. At this point it is not visible yet.
func _open() -> void:
	pass


## Called when the popup is closed. The node hides after calling this method.
func _close() -> void:
	pass


## Called when OK is pressed.
func _on_ok() -> void:
	get_tree().quit()


## Called when CANCEL or X (top-right corner) are pressed.
func _on_cancel() -> void:
	pass


#endregion
