tool
extends Resource
class_name PopochiuSettings

const ImporterDefaults := preload('res://addons/Popochiu/Engine/Others/ImporterDefaults.gd')

export(PackedScene) var graphic_interface = null
export(PackedScene) var transition_layer = null
export var skip_cutscene_time := 0.2
export var text_speeds := [0.1, 0.01, 0.0]
export var default_text_speed := 0
export var auto_continue_text := false
export var languages := ['en', 'es', 'es_CO']
export(int, 'en', 'es', 'co') var default_language := 0
export var use_translations := false
export var items_on_start := []
export var inventory_limit := 0
export var inventory_always_visible := false
export var toolbar_always_visible := false
export var fade_color: Color = Color.black
export var scale_gui := true
