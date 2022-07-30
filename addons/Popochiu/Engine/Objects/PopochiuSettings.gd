extends Resource
class_name PopochiuSettings

export var skip_cutscene_time := 0.2
export var text_speeds := [0.1, 0.01, 0.0]
export var text_speed_idx := 0
export var text_continue_auto := false
export var languages := ['en', 'es', 'es_CO']
export(int, 'en', 'es', 'co') var language_idx := 0
export var use_translations := false
export var items_on_start := []
export var inventory_limit := 0
export var inventory_always_visible := false
export var toolbar_always_visible := false
export var fade_color: Color = Color.black
