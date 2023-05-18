# Creates a new PopochiuDialog.
# 
# It creates all the necessary files to make a PopochiuDialog to work:
# - `DialogXXX.gd` > The script where the behavior for each dialog option is defined
# - `DialogXXX.tres` > The Resource file used to create the dialog options in the
# 	Inspector.
@tool
extends 'res://addons/popochiu/editor/popups/creation_popup.gd'

const DIALOG_SCRIPT_TEMPLATE :=\
'res://addons/popochiu/engine/templates/dialog_template.gd'
const Constants := preload('res://addons/popochiu/popochiu_resources.gd')
const PopochiuDock :=\
preload('res://addons/popochiu/editor/main_dock/popochiu_dock.gd')

var _new_dialog_name := ''
var _new_dialog_path := ''
var _dialog_path_template := ''
var _pascal_name := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	super()
	_clear_fields()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _create() -> void:
	if _new_dialog_name.is_empty():
		_error_feedback.show()
		return
	
	# TODO: Check if there is not already a dialog on the same PATH.
	# TODO: Delete already created files if something breaks before finishing.
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the directory where the new dialog will be saved
	DirAccess.make_dir_absolute(_main_dock.DIALOGS_PATH + _new_dialog_name)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create the script of the new dialog
	var dialog_template := load(DIALOG_SCRIPT_TEMPLATE)
	
	if ResourceSaver.save(dialog_template, _new_dialog_path + '.gd') != OK:
		push_error(
			"[Popochiu] Couldn't create script: %s.gd" % _new_dialog_name
		)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Create dialog Resource
	var dialog_resource := PopochiuDialog.new()
	dialog_resource.set_script(load(_new_dialog_path + '.gd'))
	
	dialog_resource.script_name = _pascal_name
	dialog_resource.resource_name = _new_dialog_name
	
	if ResourceSaver.save(dialog_resource, _new_dialog_path + '.tres') != OK:
		push_error("[Popochiu] Couldn't create dialog: %s" %_new_dialog_name)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Add the dialog to Popochiu
	if _main_dock.add_resource_to_popochiu(
		'dialogs', ResourceLoader.load(_new_dialog_path + '.tres')
	) != OK:
		push_error(
			"[Popochiu] Couldn't add the created dialog to Popochiu: %s" %\
			_new_dialog_name
		)
		# TODO: Show feedback in the popup
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Add the dialog to the D singleton
	PopochiuResources.update_autoloads(true)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Update the list of dialogs in the Dock
	(_main_dock as PopochiuDock).add_to_list(
		Constants.Types.DIALOG, _pascal_name
	)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Open dialog in the Inspector
	await get_tree().create_timer(0.1).timeout
	_main_dock.ei.select_file(_new_dialog_path + '.tres')
	_main_dock.ei.edit_resource(load(_new_dialog_path + '.tres'))
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# The end
	hide()


func _clear_fields() -> void:
	_new_dialog_name = ''
	_new_dialog_path = ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func set_main_dock(node: Panel) -> void:
	super(node)
	
	if not _main_dock: return
	
	# res://popochiu/dialogs
	_dialog_path_template = _main_dock.DIALOGS_PATH + '%s/dialog_%s'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_new_dialog_name = _name.to_snake_case()
		_pascal_name = _name
		_new_dialog_path = _dialog_path_template %\
		[_new_dialog_name, _new_dialog_name]

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
