@tool
extends "res://addons/popochiu/engine/interfaces/i_character.gd"

# classes ----
const PCGoddiu := preload('res://popochiu/characters/goddiu/character_goddiu.gd')
# ---- classes

# nodes ----
var Goddiu: PCGoddiu : get = get_Goddiu
# ---- nodes

# functions ----
func get_Goddiu() -> PCGoddiu: return super.get_runtime_character('Goddiu')
# ---- functions

