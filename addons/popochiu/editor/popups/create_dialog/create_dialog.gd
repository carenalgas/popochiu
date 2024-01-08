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


#region Godot ######################################################################################
func _ready() -> void:
	super()
	_clear_fields()


#endregion

#region Virtual ####################################################################################
func _create() -> void:
	if _new_dialog_name.is_empty():
		_error_feedback.show()
		return
	
	# Setup the prop helper and use it to create the prop ------------------------------------------
	_factory = PopochiuDialogFactory.new(_main_dock)

	if _factory.create(_new_dialog_name) != ResultCodes.SUCCESS:
		# TODO: show a message in the popup!
		return

	var dialog_resource = _factory.get_obj_resource()

	# Open dialog in the Inspector -----------------------------------------------------------------
	await get_tree().create_timer(0.1).timeout
	EditorInterface.select_file(dialog_resource.resource_path)
	EditorInterface.edit_resource(load(dialog_resource.resource_path))
	
	hide()


func _clear_fields() -> void:
	_new_dialog_name = ''


#endregion

#region SetGet #####################################################################################
func set_main_dock(node: Panel) -> void:
	super(node)
	
	if not _main_dock: return


#endregion

#region Private ####################################################################################
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_new_dialog_name = _name.to_snake_case()

		_info.text = (
			'In [b]%s[/b] the following files will be created:\
			\n[code]- %s\n- %s[/code]' \
			% [
				_main_dock.DIALOGS_PATH + _new_dialog_name,
				'dialog_' + _new_dialog_name + '.gd',
				'dialog_' + _new_dialog_name + '.tres'
			])
		_info.show()
	else:
		_info.clear()
		_info.hide()
	
	_update_size_and_position()


#endregion
