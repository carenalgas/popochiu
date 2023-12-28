@tool
extends "res://addons/popochiu/engine/interfaces/i_character.gd"

# classes ----
const PCGoddiu := preload('res://game/characters/goddiu/character_goddiu.gd')
const PCCoco := preload('res://game/characters/coco/character_coco.gd')
# ---- classes

# nodes ----
var Goddiu: PCGoddiu : get = get_Goddiu
var Coco: PCCoco : get = get_Coco
# ---- nodes

# functions ----
func get_Goddiu() -> PCGoddiu: return super.get_runtime_character('Goddiu')
func get_Coco() -> PCCoco: return super.get_runtime_character('Coco')
# ---- functions

