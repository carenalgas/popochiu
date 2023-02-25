@tool
extends "res://addons/Popochiu/Engine/Interfaces/IAudio.gd"

# classes ----
const AudioCueSound := preload("res://addons/Popochiu/Engine/AudioManager/AudioCueSound.gd")
const AudioCueMusic := preload("res://addons/Popochiu/Engine/AudioManager/AudioCueMusic.gd")
# ---- classes

# cues ----
var mx_house: AudioCueMusic = preload("res://popochiu/Rooms/House/audio/MxHouse.tres")
# ---- cues

