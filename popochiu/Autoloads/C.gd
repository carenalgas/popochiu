extends "res://addons/Popochiu/Engine/Interfaces/ICharacter.gd"

# classes ----
const PCGoddiu := preload('res://popochiu/Characters/Goddiu/CharacterGoddiu.gd')
const PCPopsy := preload('res://popochiu/Characters/Popsy/CharacterPopsy.gd')
const PCTrapusinsiu := preload('res://popochiu/Characters/Trapusinsiu/CharacterTrapusinsiu.gd')
# ---- classes

# nodes ----
var Goddiu: PCGoddiu setget , get_Goddiu
var Popsy: PCPopsy setget , get_Popsy
var Trapusinsiu: PCTrapusinsiu setget , get_Trapusinsiu
# ---- nodes

# functions ----
func get_Goddiu(): return .get_runtime_character('Goddiu')
func get_Popsy(): return .get_runtime_character('Popsy')
func get_Trapusinsiu(): return .get_runtime_character('Trapusinsiu')
# ---- functions
