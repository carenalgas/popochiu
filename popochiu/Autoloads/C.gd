@tool
extends "res://addons/Popochiu/Engine/Interfaces/ICharacter.gd"

# classes ----
const PCGoddiu := preload('res://popochiu/Characters/Goddiu/CharacterGoddiu.gd')
const PCPopsy := preload('res://popochiu/Characters/Popsy/CharacterPopsy.gd')
# ---- classes

# nodes ----
var Goddiu: PCGoddiu : get = get_Goddiu
var Popsy: PCPopsy : get = get_Popsy
# ---- nodes

# functions ----
func get_Goddiu() -> PCGoddiu: return super.get_runtime_character('Goddiu')
func get_Popsy() -> PCPopsy: return super.get_runtime_character('Popsy')
# ---- functions
