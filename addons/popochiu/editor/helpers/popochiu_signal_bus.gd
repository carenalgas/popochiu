extends RefCounted
## Helper Editor class to emit and connect to signals across different components in the plugin

signal main_scene_changed(scene_path: String)
signal pc_changed(script_name: String)
signal audio_cues_deleted(cue_file_paths: Array)
signal main_object_added(type: int, name_to_add: String)
signal gizmo_visibility_changed(gizmo: int, visible: bool)
signal migrations_done
