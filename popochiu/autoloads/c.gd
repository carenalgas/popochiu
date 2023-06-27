@tool
extends "res://addons/popochiu/engine/interfaces/i_character.gd"

# classes ----
const PCGoddiu := preload('res://popochiu/characters/goddiu/character_goddiu.gd')
const PCPopsy := preload('res://popochiu/characters/popsy/character_popsy.gd')
const PCTrapusinsiu := preload('res://popochiu/characters/trapusinsiu/character_trapusinsiu.gd')
const PC01 := preload('res://popochiu/characters/01/character_01.gd')
# ---- classes

# nodes ----
var Goddiu: PCGoddiu : get = get_Goddiu
var Popsy: PCPopsy : get = get_Popsy
var Trapusinsiu: PCTrapusinsiu : get = get_Trapusinsiu
var C01: PC01 : get = get_01
# ---- nodes

# functions ----
func get_Goddiu() -> PCGoddiu: return super.get_runtime_character('Goddiu')
func get_Popsy() -> PCPopsy: return super.get_runtime_character('Popsy')
func get_Trapusinsiu() -> PCTrapusinsiu: return super.get_runtime_character('Trapusinsiu')
func get_01() -> PC01: return super.get_runtime_character('01')
# ---- functions
