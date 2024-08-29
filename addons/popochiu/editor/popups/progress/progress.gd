@tool
extends Control

@onready var label: Label = %Label
@onready var progress_bar: ProgressBar = %ProgressBar


#region Public #####################################################################################
func close() -> void:
	get_parent().queue_free()


#endregion
