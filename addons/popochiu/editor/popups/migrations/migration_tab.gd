@tool
extends PanelContainer

const INCOMPLETED_FORMAT = "[code][color=b2b2b2]%s[/color][/code]"

var _steps := []

@onready var description: Label = %Description
@onready var steps: RichTextLabel = %Steps


#region Public #####################################################################################
func set_steps(steps_texts: Array) -> void:
	_steps = steps_texts.map(
		func (step: String) -> String:
			return "- [ ] %s\n" % step
	)
	steps.text = INCOMPLETED_FORMAT % _get_steps_text(_steps)


func start_step(idx: int) -> void:
	var steps_copy := _steps.duplicate()
	steps_copy[idx] = "[color=edf171]%s[/color]" % steps_copy[idx]
	steps.text = INCOMPLETED_FORMAT % _get_steps_text(steps_copy)


func mark_steps(completed: Array) -> void:
	for idx: int in completed:
		_steps[idx] = "[color=a9ff9f]%s[/color]" % _steps[idx].replace("- [ ]", "- [X]")
	
	steps.text = INCOMPLETED_FORMAT % _get_steps_text(_steps)


#endregion

#region Private ####################################################################################
func _get_steps_text(steps_texts: Array) -> String:
	return _steps.reduce(func (accum: String, step: String): return accum + step, "")


#endregion
