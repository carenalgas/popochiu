@tool
extends "res://addons/popochiu/engine/interfaces/i_dialog.gd"

# classes ----
const PDPopsyChat := preload('res://popochiu/dialogs/popsy_chat/dialog_popsy_chat.gd')
# ---- classes

# nodes ----
var PopsyChat: PDPopsyChat : get = get_PopsyChat
# ---- nodes

# functions ----
func get_PopsyChat() -> PDPopsyChat: return E.get_dialog('PopsyChat')
# ---- functions

