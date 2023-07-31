# Creates a PopochiuInventoryItem.
# 
# It creates all the necessary files to make a PopochiuInventoryItem to work and
# to store its state:
# - InventoryXXX.tsn
# - InventoryXXX.gd
# - InventoryXXX.tres
# - InventoryXXXState.gd
@tool
extends 'res://addons/popochiu/editor/popups/creation_popup.gd'

# TODO: Giving a proper class name to PopochiuDock eliminates the need to preload it
# and to cast it as the right type later in code.
const PopochiuDock := preload('res://addons/popochiu/editor/main_dock/popochiu_dock.gd')

var _new_item_name := ''
var _helper: PopochiuInventoryItemFactory


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ GODOT ░░░░
func _ready() -> void:
	super()
	_clear_fields()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func _create() -> void:
	if _new_item_name.is_empty():
		_error_feedback.show()
		return
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Setup the prop helper and use it to create the prop
	_helper = PopochiuInventoryItemFactory.new(_main_dock)

	var item_scene = _helper.create(_new_item_name)

	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# Open the scene in the editor
	await get_tree().create_timer(0.1).timeout
	_main_dock.ei.select_file(item_scene.scene_file_path)
	_main_dock.ei.open_scene_from_path(item_scene.scene_file_path)
	
	# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
	# That's all!!!!!!!
	hide()


func _clear_fields() -> void:
	_new_item_name = ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ SET & GET ░░░░
func set_main_dock(node: Panel) -> void:
	super(node)
	
	if not _main_dock: return
	

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _update_name(new_text: String) -> void:
	super(new_text)

	if _name:
		_new_item_name = _name.to_snake_case()

		_info.text = (
			'In [b]%s[/b] the following files will be created:\
			\n[code]%s, %s and %s[/code]' \
			% [
				_main_dock.INVENTORY_ITEMS_PATH + _new_item_name,
				'inventory_item_' + _new_item_name + '.tscn',
				'inventory_item_' + _new_item_name + '.gd',
				'inventory_item_' + _new_item_name + '.tres'
			]
		)
		_info.show()
	else:
		_info.clear()
		_info.hide()
