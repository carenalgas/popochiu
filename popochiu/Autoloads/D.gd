@tool
extends "res://addons/Popochiu/Engine/Interfaces/IDialog.gd"

# classes ----
const PDTestA := preload('res://popochiu/Dialogs/TestA/DialogTestA.gd')
# ---- classes

# nodes ----
var TestA: PDTestA : get = get_TestA
# ---- nodes

# functions ----
func get_TestA() -> PDTestA: return E.get_dialog('TestA')
# ---- functions

