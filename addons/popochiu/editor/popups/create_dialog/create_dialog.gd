# Creates a new PopochiuDialog.
# 
# It creates all the necessary files to make a PopochiuDialog to work:
# - `DialogXXX.gd` > The script where the behavior for each dialog option is defined
# - `DialogXXX.tres` > The Resource file used to create the dialog options in the
# 	Inspector.
@tool
extends 'res://addons/popochiu/editor/popups/creation_popup.gd'

# TODO: Giving a proper class name to PopochiuDock eliminates the need to preload it
# and to cast it as the right type later in code.
const PopochiuDock := preload('res://addons/popochiu/editor/main_dock/popochiu_dock.gd')

var _new_dialog_name := ''
var _factory: PopochiuDialogFactory


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	super()
	_clear_fields()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _create() -> void:
	if _new_dialog_name.is_empty():
		_error_feedback.show()
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Setup the prop helper and use it to create the prop
	_factory = PopochiuDialogFactory.new(_main_dock)

	var dialog_resource = _factory.create(_new_dialog_name)

	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Open dialog in the Inspector
	await get_tree().create_timer(0.1).timeout
	_main_dock.ei.select_file(dialog_resource.resource_path)
	_main_dock.ei.edit_resource(load(dialog_resource.resource_path))
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# The end
	hide()


func _clear_fields() -> void:
	_new_dialog_name = ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func set_main_dock(node: Panel) -> void:
	super(node)
	
	if not _main_dock: return


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_new_dialog_name = _name.to_snake_case()

		_info.text = (
			'In [b]%s[/b] the following files will be created:\
			\n[code]%s and %s[/code]' \
			% [
				_main_dock.DIALOGS_PATH + _new_dialog_name,
				'dialog_' + _new_dialog_name + '.gd',
				'dialog_' + _new_dialog_name + '.tres'
			])
		_info.show()
	else:
		_info.clear()
		_info.hide()
