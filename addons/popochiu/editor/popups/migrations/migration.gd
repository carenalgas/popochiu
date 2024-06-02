@tool
extends PanelContainer

var _steps := []

@onready var description: Label = %Description
@onready var steps: RichTextLabel = %Steps


#region Public #####################################################################################
func set_steps(steps_texts: Array) -> void:
	_steps = steps_texts
	_steps = steps_texts.map(
		func (step: String) -> String:
			return "- [ ] %s\n" % step
	)
	steps.text = "[code]%s[/code]" % _steps


func mark_steps(completed: Array) -> void:
	for idx: int in completed:
		_steps[idx].replace("- [ ]", "- [X]")
	
	steps.text = "[code]%s[/code]" % _steps


#endregion
