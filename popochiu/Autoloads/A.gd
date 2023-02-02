tool
extends "res://addons/Popochiu/Engine/Interfaces/IAudio.gd"

# classes ----
const AudioCueSound := preload("res://addons/Popochiu/Engine/AudioManager/AudioCueSound.gd")
const AudioCueMusic := preload("res://addons/Popochiu/Engine/AudioManager/AudioCueMusic.gd")
# ---- classes

# cues ----
var sfx_toy_car: AudioCueSound = preload("res://popochiu/InventoryItems/ToyCar/SfxToyCar.tres")
var mx_two_popochius: AudioCueMusic = preload("res://popochiu/Rooms/101/audio/MxTwoPopochius.tres")
# ---- cues

