@tool
class_name PopochiuMigration10
extends PopochiuMigration

const VERSION = 10
const DESCRIPTION = "Create the transition layer folder and files in the game folder"
const STEPS = [
	"Create transition layer folder structure",
	"Copy transition layer scene to game folder",
	"Create transition layer script",
	"Add User animation library",
	"Update E.play_transition() calls to new signature"
]


#region Virtual ####################################################################################
func _is_migration_needed() -> bool:
	# Migration is needed if the game folder exists but the transition layer scene doesn't
	return (
		DirAccess.dir_exists_absolute(PopochiuResources.GAME_PATH)
		and not FileAccess.file_exists(PopochiuResources.TRANSITION_LAYER_SCENE)
	)


func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			_create_folder_structure,
			_copy_transition_layer_scene,
			_create_transition_layer_script,
			_add_user_animation_library,
			_update_play_transition_calls
		]
	)


#endregion


#region Private ####################################################################################
func _create_folder_structure() -> Completion:
	# Create the transition layer folder and textures subfolder
	if not DirAccess.dir_exists_absolute(PopochiuResources.TRANSITION_LAYER_PATH):
		DirAccess.make_dir_recursive_absolute(PopochiuResources.TRANSITION_LAYER_PATH)

	if not DirAccess.dir_exists_absolute(PopochiuResources.TRANSITION_LAYER_MASKS):
		DirAccess.make_dir_recursive_absolute(PopochiuResources.TRANSITION_LAYER_MASKS)

	return Completion.DONE


func _copy_transition_layer_scene() -> Completion:
	if FileAccess.file_exists(PopochiuResources.TRANSITION_LAYER_SCENE):
		return Completion.IGNORED

	var base_scene = load(PopochiuResources.TL_BASE_SCENE) as PackedScene
	if not base_scene:
		PopochiuUtils.print_error("Couldn't load the base transition layer scene.")
		return Completion.FAILED

	if ResourceSaver.save(base_scene, PopochiuResources.TRANSITION_LAYER_SCENE) != OK:
		PopochiuUtils.print_error("Couldn't copy the transition layer scene.")
		return Completion.FAILED

	return Completion.DONE


func _create_transition_layer_script() -> Completion:
	if FileAccess.file_exists(PopochiuResources.TRANSITION_LAYER_SCRIPT):
		return Completion.IGNORED

	var tl_file = FileAccess.open(PopochiuResources.TRANSITION_LAYER_SCRIPT, FileAccess.WRITE)
	if not tl_file:
		PopochiuUtils.print_error("Couldn't create the transition layer script.")
		return Completion.FAILED

	tl_file.store_line("@tool")
	tl_file.store_line("extends PopochiuTransitionLayer")
	tl_file.close()

	# Assign the script to the scene
	var scene = (load(PopochiuResources.TRANSITION_LAYER_SCENE) as PackedScene).instantiate()
	scene.set_script(load(PopochiuResources.TRANSITION_LAYER_SCRIPT))

	var packed_scene := PackedScene.new()
	packed_scene.pack(scene)

	if ResourceSaver.save(packed_scene, PopochiuResources.TRANSITION_LAYER_SCENE) != OK:
		PopochiuUtils.print_error("Couldn't assign the transition layer script to the scene.")
		return Completion.FAILED

	return Completion.DONE


func _add_user_animation_library() -> Completion:
	# Load the transition layer scene and add the User animation library if it doesn't exist
	var scene = (load(PopochiuResources.TRANSITION_LAYER_SCENE) as PackedScene).instantiate()
	if not scene:
		PopochiuUtils.print_error("Couldn't load the transition layer scene.")
		return Completion.FAILED

	var animation_player = scene.get_node("AnimationPlayer")
	if not animation_player:
		PopochiuUtils.print_error("Couldn't find AnimationPlayer in the transition layer scene.")
		return Completion.FAILED

	# Check if the User library already exists
	if animation_player.has_animation_library(PopochiuResources.TRANSITION_LAYER_CUSTOM_ANIMLIB):
		return Completion.IGNORED

	# Add the User animation library
	animation_player.add_animation_library(
		PopochiuResources.TRANSITION_LAYER_CUSTOM_ANIMLIB, AnimationLibrary.new()
	)

	# Save the scene
	var packed_scene := PackedScene.new()
	packed_scene.pack(scene)

	if ResourceSaver.save(packed_scene, PopochiuResources.TRANSITION_LAYER_SCENE) != OK:
		PopochiuUtils.print_error("Couldn't save the transition layer scene with the User library.")
		return Completion.FAILED

	return Completion.DONE


func _update_play_transition_calls() -> Completion:
	# Update E.play_transition() calls to the new signature
	# #156~ Old signature: E.play_transition(mode, duration)
	# New signature: E.play_transition(animation_name, duration, play_mode)
	var replacements: Array[Dictionary] = [
		{
			pattern = r"E\.play_transition\(PopochiuTransitionLayer\.FADE_IN,\s*([^)]+)\)",
			to = r'T.play_transition("", $1, PopochiuTransitionLayer.PLAY_MODE.IN)'
		},
		{
			pattern = r"E\.play_transition\(PopochiuTransitionLayer\.FADE_OUT,\s*([^)]+)\)",
			to = r'T.play_transition("", $1, PopochiuTransitionLayer.PLAY_MODE.OUT)'
		},
		{
			pattern = r"E\.play_transition\(PopochiuTransitionLayer\.FADE_IN_OUT,\s*([^)]+)\)",
			to = r'T.play_transition("", $1, PopochiuTransitionLayer.PLAY_MODE.IN_OUT)'
		}
	]
	
	var replaced := PopochiuMigrationHelper.replace_regex_in_scripts(replacements)
	return Completion.DONE if replaced else Completion.IGNORED


#endregion
