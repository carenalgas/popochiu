tool
extends HBoxContainer

signal tag_state_changed

const result_code = preload("../config/result_codes.gd")
var _config

var _anim_tag_state: Dictionary = {}

onready var import_toggle = $HBoxContainer/Import
onready var tag_name_label = $HBoxContainer/TagName
onready var loops_toggle = $Panel/Loops

func init(config, tag_cfg: Dictionary):
	if tag_cfg.tag_name == null or tag_cfg.tag_name == "":
		printerr(result_code.get_error_message(result_code.ERR_UNNAMED_TAG_DETECTED))
		return false

	_config = config
	_anim_tag_state = _load_default_tag_state()
	_anim_tag_state.merge(tag_cfg, true)
	_setup_scene()


func _setup_scene():
	import_toggle.pressed = _anim_tag_state.import
	loops_toggle.pressed = _anim_tag_state.loops
	tag_name_label.text = _anim_tag_state.tag_name


func _load_default_tag_state() -> Dictionary:
	return {
		"tag_name": "",
		"import": _config.is_default_animation_import_enabled(),
		"loops": _config.is_default_animation_loop_enabled(),
	}


func get_cfg() -> Dictionary:
	return _anim_tag_state


func _on_import_toggled(button_pressed):
	_anim_tag_state.import = button_pressed
	emit_signal("tag_state_changed")


func _on_loops_toggled(button_pressed):
	_anim_tag_state.loops = button_pressed
	emit_signal("tag_state_changed")
