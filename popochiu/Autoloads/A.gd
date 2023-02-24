@tool
extends "res://addons/Popochiu/Engine/Interfaces/IAudio.gd"

# classes ----
const AudioCueSound := preload("res://addons/Popochiu/Engine/AudioManager/AudioCueSound.gd")
const AudioCueMusic := preload("res://addons/Popochiu/Engine/AudioManager/AudioCueMusic.gd")
# ---- classes

# cues ----
var vo_goddiu_01: AudioCueSound = preload("res://popochiu/Characters/Goddiu/audio/VoGoddiu01.tres")
var mx_two_popochius: AudioCueMusic = preload("res://popochiu/Rooms/101/audio/MxTwoPopochius.tres")
# ---- cues

