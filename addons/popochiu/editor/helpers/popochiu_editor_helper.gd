@tool
class_name PopochiuEditorHelper
extends Resource
## Utils class for Editor related things.

static var ei := EditorInterface
static var undo_redo: EditorUndoRedoManager = null


static func select_node(node: Node) -> void:
	ei.get_selection().clear()
	ei.get_selection().add_node(node)
