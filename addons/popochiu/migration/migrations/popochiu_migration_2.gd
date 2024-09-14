@tool
class_name PopochiuMigration2
extends PopochiuMigration
## Migrates projects from Beta to Release.

const VERSION = 2
const DESCRIPTION = "Make changes from beta-x to 2.0.0 release"
const STEPS = [
	"Update external scenes and assign scripts that didn't exist before. (pre [i]release[/i])",
	"Add a [b]ScalingPolygon[/b] node to each [b]PopochiuCharacter[/b]. (pre [i]beta 1[/i])",
	"Move popochiu_settings.tres to ProjectSettings. (pre [i]beta 3[/i])",
	#"Update the DialogMenu GUI component. (pre [i]beta 3[/i])",
	#"(Optional) Update SettingsBar in 2-click Context-sensitive GUI template. (pre [i]beta 3[/i])",
	"Remove [b]BaselineHelper[/b] and [b]WalkToHelper[/b] nodes in [b]PopochiuClickable[/b]s." \
	+ " Also remove [b]DialogPos[/b] node in [b]PopochiuCharacter[/b]s. (pre [i]release[/i])",
	"Update uses of deprecated properties and methods. (pre [i]release[/i])",
	"Update rooms sizes",
]
const RESET_CHILDREN_OWNER = "reset_children_owner"
const GAME_INVENTORY_BAR_PATH =\
"res://game/gui/components/inventory_bar/inventory_bar.tscn"
const GAME_SETTINGS_BAR_PATH =\
"res://game/gui/components/settings_bar/settings_bar.tscn"
const GAME_DIALOG_MENU_PATH = "res://game/gui/components/dialog_menu/dialog_menu.tscn"
const GAME_DIALOG_MENU_OPTION_PATH =\
"res://game/gui/components/dialog_menu/dialog_menu_option/"
const ADDON_DIALOG_MENU_PATH =\
"res://addons/popochiu/engine/objects/gui/components/dialog_menu/dialog_menu.tscn"
const TextSpeedOption = preload(
	PopochiuResources.GUI_ADDON_FOLDER + "components/settings_bar/resources/text_speed_option.gd"
)

var _gui_templates_helper := preload(
	"res://addons/popochiu/editor/helpers/popochiu_gui_templates_helper.gd"
)


#region Virtual ####################################################################################
## This is code specific for this migration. This should return [code]true[/code] if the migration
## is successful. This is called from [method do_migration] which checks to make sure the migration
## should be done before calling this.
func _do_migration() -> bool:
	return await PopochiuMigrationHelper.execute_migration_steps(
		self,
		[
			_update_objects_in_rooms,
			_add_scaling_polygon_to_characters,
			_move_settings_to_project_settings,
			#_update_dialog_menu,
			#_update_simple_click_settings_bar,
			_remove_helper_nodes,
			_replace_deprecated,
			_update_rooms_sizes,
		]
	)


#endregion

#region Private ####################################################################################
## Update external prop scenes and assign missing scripts for each prop, hotspot, region, and
## walkable area that didn't exist prior [i]beta 1[/i].
func _update_objects_in_rooms() -> Completion:
	var any_room_updated := PopochiuUtils.any_exhaustive(
		PopochiuEditorHelper.get_rooms(), _update_room
	)
	
	_reload_needed = any_room_updated
	return Completion.DONE if any_room_updated else Completion.IGNORED


## Update the children of the different groups in [param popochiu_room] so the use instances of the
## new objects: [PopochiuProp], [PopochiuHotspot], [PopochiuRegion], and [PopochiuWalkableArea].
func _update_room(popochiu_room: PopochiuRoom) -> bool:
	var room_objects_to_add := []
	var room_objects_to_check := []
	PopochiuUtils.any_exhaustive([
		PopochiuPropFactory.new(),
		PopochiuHotspotFactory.new(),
		PopochiuRegionFactory.new(),
		PopochiuWalkableAreaFactory.new(),
		PopochiuMarkerFactory.new(),
	], _create_new_room_objects.bind(popochiu_room, room_objects_to_add, room_objects_to_check))
	
	for group: Dictionary in room_objects_to_add:
		group.objects.all(
			func (new_obj) -> bool:
				# Set the owner of the new object and do the same for its children (those that
				# were marked as PopochiuRoomObjFactory.CHILD_VISIBLE_IN_ROOM_META)
				new_obj.owner = popochiu_room
				
				for child: Node in new_obj.get_meta(RESET_CHILDREN_OWNER):
					child.owner = popochiu_room
				new_obj.remove_meta(RESET_CHILDREN_OWNER)
				
				return true
		)
	
	if PopochiuEditorHelper.pack_scene(popochiu_room) != OK:
		PopochiuUtils.print_error(
			"Migration 2: Couldn't update [b]%s[/b] after adding new nodes." %
			popochiu_room.script_name
		)
	
	var room_object_updated := false
	for obj: Node2D in room_objects_to_check:
		# Check if the node's scene has all the expected nodes based on its base scene
		var added_nodes := _add_lacking_nodes(obj)
		if added_nodes and not room_object_updated:
			room_object_updated = added_nodes
	
	if room_object_updated and PopochiuEditorHelper.pack_scene(popochiu_room) != OK:
		PopochiuUtils.print_error(
			"Migration 2: Couldn't update [b]%s[/b] after adding lacking nodes." %
			popochiu_room.script_name
		)
	
	return !room_objects_to_add.is_empty() or room_object_updated


## Create a new scene of the [param factory] type. The scene will be placed in its corresponding
## folder inside the [param popochiu_room] folder. Created [Node]s will be stored in
## [param room_objects_to_add] so they are added to the room later.
func _create_new_room_objects(
	factory: PopochiuRoomObjFactory,
	popochiu_room: PopochiuRoom,
	room_objects_to_add := [],
	room_objects_to_check := []
) -> bool:
	var created_objects := []
	for obj in _get_room_objects(
		popochiu_room.get_node(factory.get_group()),
		[],
		factory.get_type_method()
	):
		# Copy the points of the polygons that were previously a node visible in the Room tree, but
		# now are only properties
		if (
			(obj is PopochiuProp or obj is PopochiuHotspot or obj is PopochiuRegion)
			and (obj.has_node("InteractionPolygon") or obj.has_node("InteractionPolygon2"))
		):
			var interaction_polygon: CollisionPolygon2D = obj.get_node("InteractionPolygon")
			if obj.has_node("InteractionPolygon2"):
				interaction_polygon = obj.get_node("InteractionPolygon2")
			
			if interaction_polygon.owner == popochiu_room:
				# Store the polygon vectors into the new @export variable
				obj.interaction_polygon = interaction_polygon.polygon
				obj.interaction_polygon_position = interaction_polygon.position
				# Delete the CollisionPolygon2D node that in previous versions was attached to the
				# room
				interaction_polygon.owner = null
				interaction_polygon.free()
		elif (
			obj is PopochiuWalkableArea
			and (obj.has_node("Perimeter") or obj.has_node("Perimeter2"))
		):
			var perimeter: NavigationRegion2D = obj.get_node("Perimeter")
			if obj.has_node("Perimeter2"):
				perimeter = obj.get_node("Perimeter2")
			
			if perimeter.owner == popochiu_room:
				# Store the navigation polygon vectors into the new @export variable
				obj.map_navigation_polygon(perimeter)
				# Delete the NavigationRegion2D node that in previous versions was attached to the
				# room
				perimeter.owner = null
				perimeter.free()
		
		# If the object already has its own scene and a script that is not inside Popochiu's folder,
		# then just check if there are lacking nodes inside its scene
		if (
			not obj.scene_file_path.is_empty()
			and not "addons" in obj.scene_file_path
			and not "addons" in obj.get_script().resource_path
		):
			room_objects_to_check.append(obj)
			continue
		
		# Create the new scene (and script if needed) of the [obj]
		var obj_factory: PopochiuRoomObjFactory = factory.get_new_instance()
		if obj_factory.create_from(obj, popochiu_room) != ResultCodes.SUCCESS:
			continue
		
		# Map the properties of the [obj] to its new instance
		created_objects.append(_create_new_room_obj(obj_factory, obj, popochiu_room))
	
	if created_objects.is_empty():
		return false
	
	room_objects_to_add.append({
		factory = factory,
		objects = created_objects
	})
	
	return true


## Recursively search for nodes of a specific type in the [param parent] and its children. The nodes
## found are added to the [param objects] array. The [param type_method] is used to determine if a
## node is the desired type.
func _get_room_objects(parent: Node, objects: Array, type_method: Callable) -> Array:
	for child: Node in parent.get_children():
		if type_method.call(child):
			objects.append(child)
		else:
			# If the child is a Node containing other nodes, go deeper in the tree looking for room
			# object nodes
			_get_room_objects(child, objects, type_method)
	
	return objects


## Maps the properties (and nodes if needed) of [param source] to a new instance of itself created
## from [param obj_factory]. This assures that objects coming from versions prior to [i]beta 1[/i]
## will have the corresponding structure of new Popochiu versions.
func _create_new_room_obj(
	obj_factory: PopochiuRoomObjFactory, source: Node, room: PopochiuRoom
) -> Node:
	var new_obj: Node = (ResourceLoader.load(
		obj_factory.get_scene_path()
	) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	new_obj.set_meta(RESET_CHILDREN_OWNER, [])
	
	source.name += "_"
	source.get_parent().add_child(new_obj)
	source.get_parent().move_child(new_obj, source.get_index())
	
	# Check if the original object has a script attached (different from the default one)
	if (
		source.get_script()
		and not "addons" in source.get_script().resource_path
		and source.get_script().resource_path != new_obj.get_script().resource_path
	):
		# Change the default script by the one attached to the original object
		new_obj.set_script(load(source.get_script().resource_path))
		
		# Copy its extra properties (those declared as vars in the script) to the new instance
		PopochiuResources.copy_popochiu_object_properties(
			new_obj, source, PopochiuResources[
				"%s_IGNORE" % obj_factory.get_group().to_snake_case().to_upper()
			]
		)
	
	new_obj.position = source.position
	new_obj.scale = source.scale
	new_obj.z_index = source.z_index
	
	if new_obj is PopochiuProp or new_obj is PopochiuHotspot:
		new_obj.baseline = source.baseline
		new_obj.walk_to_point = source.walk_to_point
	
	if new_obj is PopochiuProp:
		new_obj.texture = source.texture
		new_obj.frames = source.frames
		new_obj.v_frames = source.v_frames
		new_obj.link_to_item = source.link_to_item
		new_obj.interaction_polygon = source.interaction_polygon
		new_obj.interaction_polygon_position = source.interaction_polygon_position
		
		if obj_factory.get_snake_name() in ["bg", "background"]:
			new_obj.z_index = -1
	
	if new_obj is PopochiuRegion:
		new_obj.interaction_polygon = source.interaction_polygon
		new_obj.interaction_polygon_position = source.interaction_polygon_position
	
	if new_obj is PopochiuWalkableArea:
		new_obj.interaction_polygon = source.interaction_polygon
		new_obj.interaction_polygon_position = source.interaction_polygon_position
	
	# Remove the old [source] node from the room
	source.free()
	
	return new_obj


## Checks the [code].tscn[/code] file of [param source] for lacking nodes based on its type. If
## there are any, then it will add them so the structure of the scene matches the one of the object
## it inherits from.
func _add_lacking_nodes(source: Node) -> bool:
	var obj_scene: Node2D = ResourceLoader.load(source.scene_file_path).instantiate()
	var was_updated := false
	
	if (
		PopochiuEditorHelper.is_prop(obj_scene)
		or PopochiuEditorHelper.is_hotspot(obj_scene)
		or PopochiuEditorHelper.is_region(obj_scene)
	) and not obj_scene.has_node("InteractionPolygon"):
		var interaction_polygon := CollisionPolygon2D.new()
		interaction_polygon.name = "InteractionPolygon"
		interaction_polygon.polygon = PackedVector2Array([
			Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)
		])
		obj_scene.add_child(interaction_polygon)
		obj_scene.move_child(interaction_polygon, 0)
		interaction_polygon.owner = obj_scene
		was_updated = true
	elif PopochiuEditorHelper.is_walkable_area(obj_scene) and not obj_scene.has_node("Perimeter"):
		var perimeter := NavigationRegion2D.new()
		perimeter.name = "Perimeter"
		var polygon := NavigationPolygon.new()
		polygon.agent_radius = 0.0
		perimeter.navigation_polygon = polygon
		obj_scene.add_child(perimeter)
		perimeter.owner = obj_scene
		obj_scene.interaction_polygon = source.interaction_polygon
		obj_scene.clear_and_bake(perimeter.navigation_polygon)
		was_updated = true
	
	if PopochiuEditorHelper.is_prop(obj_scene) and not obj_scene.has_node("AnimationPlayer"):
		var animation_player := AnimationPlayer.new()
		obj_scene.add_child(animation_player)
		animation_player.owner = obj_scene
		was_updated = true
	
	if was_updated:
		PopochiuEditorHelper.pack_scene(obj_scene)
	
	return was_updated


## Add a [CollisionPolygon2D] node named "ScalingPolygon" to each [PopochiuCharacter] that doesn't
## have it. Returns [code]Completion.DONE[/code] if any character is updated, 
## [code]Completion.IGNORED[/code] otherwise.
func _add_scaling_polygon_to_characters() -> Completion:
	# Get the characters' .tscn files
	var file_paths := PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(
		PopochiuResources.CHARACTERS_PATH,
		["tscn"]
	)
	var any_character_updated := PopochiuUtils.any_exhaustive(file_paths, _add_scaling_polygon_to)
	return Completion.DONE if any_character_updated else Completion.IGNORED


## Loads the [PopochiuCharacter] in [param scene_path] and add a [CollisionPolygon2D] node if it
## doesn't has a [code]ScalingPolygon[/code] child.
func _add_scaling_polygon_to(scene_path: String) -> bool:
	var popochiu_character: PopochiuCharacter = (load(scene_path) as PackedScene).instantiate()
	var was_scene_updated := false
	
	# ---- Add the ScalingPolygon node if needed ---------------------------------------------------
	if not popochiu_character.has_node("ScalingPolygon"):
		was_scene_updated = true
		var scaling_polygon := CollisionPolygon2D.new()
		scaling_polygon.name = "ScalingPolygon"
		scaling_polygon.polygon = PackedVector2Array([
			Vector2(-5, -5), Vector2(5, -5), Vector2(5, 5), Vector2(-5, 5)
		])
		popochiu_character.add_child(scaling_polygon)
		popochiu_character.move_child(scaling_polygon, 1)
		scaling_polygon.owner = popochiu_character
	
	if was_scene_updated and PopochiuEditorHelper.pack_scene(popochiu_character) != OK:
		PopochiuUtils.print_error(
			"Couldn't update [b]%s[/b] with new voices array." % popochiu_character.script_name
		)
	
	return was_scene_updated


## Move the values from the old [code]popochiu_settings.tres[/code] file to the new 
## [code]Project Settings > Popochiu[/code] section. Returns [constant Completion.DONE] if the values
## are moved, [constant Completion.IGNORED] if the file doesn't exist, [constant Completion.FAILED]
## otherwise.
func _move_settings_to_project_settings() -> Completion:
	var old_settings_file := PopochiuMigrationHelper.old_settings_file
	
	if not FileAccess.file_exists(old_settings_file):
		return Completion.IGNORED
	
	# Move custom defined values in the old [popochiu_settings.tres] file to Project Settings
	var old_settings: PopochiuSettings = load(old_settings_file)
	var settings_map := {
		# ---- GUI ---------------------------------------------------------------------------------
		"SCALE_GUI": "",
		"FADE_COLOR": "",
		"SKIP_CUTSCENE_TIME": "",
		# ---- Dialogs -----------------------------------------------------------------------------
		"TEXT_SPEED": old_settings.text_speeds[old_settings.default_text_speed],
		"AUTO_CONTINUE_TEXT": "",
		"USE_TRANSLATIONS": "",
		# ---- Inventory ---------------------------------------------------------------------------
		"INVENTORY_LIMIT": "",
		# ---- Pixel game --------------------------------------------------------------------------
		"PIXEL_ART_TEXTURES": "is_pixel_art_game",
		"PIXEL_PERFECT": "is_pixel_perfect",
	}
	
	for key: String in settings_map:
		PopochiuConfig.set_project_setting(
			key,
			old_settings[key.to_lower()] if key.is_empty() else settings_map[key]
		)
	
	for item_name: StringName in old_settings.items_on_start:
		var items_on_start := PopochiuConfig.get_inventory_items_on_start()
		items_on_start.append(str(item_name))
		PopochiuConfig.set_inventory_items_on_start(items_on_start)
	
	# Move custom defined values in the old [popochiu_settings.tres] to their corresponding GUI
	# components
	if FileAccess.file_exists(GAME_INVENTORY_BAR_PATH):
		var inventory_bar: Control = load(GAME_INVENTORY_BAR_PATH).instantiate()
		inventory_bar.always_visible = old_settings.inventory_always_visible
		PopochiuEditorHelper.pack_scene(inventory_bar)
	
	if FileAccess.file_exists(GAME_SETTINGS_BAR_PATH):
		var settings_bar: PanelContainer = load(GAME_SETTINGS_BAR_PATH).instantiate()
		settings_bar.always_visible = old_settings.toolbar_always_visible
		PopochiuEditorHelper.pack_scene(settings_bar)
	
	# Remove the old [popochiu_settings.tres]
	if DirAccess.remove_absolute(old_settings_file) != OK:
		PopochiuUtils.print_error("Couldn't delete [code]%s[/code]." % old_settings_file)
		return Completion.FAILED
	
	return Completion.DONE


## Update the [code]DialogMenu[/code] GUI component to use the new [code]DialogMenuOption[/code].
## Returns [constant Completion.DONE] if the component is updated, [constant Completion.IGNORED] if 
## the game's GUI is not using the [code]DialogMenu[/code] component or is already using the new 
## version, [constant Completion.FAILED] otherwise.
func _update_dialog_menu() -> Completion:
	if (
		not FileAccess.file_exists(GAME_DIALOG_MENU_PATH)
		or DirAccess.dir_exists_absolute(GAME_DIALOG_MENU_OPTION_PATH)
	):
		# The game's GUI is not using the DialogMenu GUI component or is already using its beta-3
		# version
		return Completion.IGNORED
	
	# Copy the new [PopochiuDialogMenuOption] component to the game's GUI components folder
	await _gui_templates_helper.copy_components(ADDON_DIALOG_MENU_PATH)
	
	# Store the scene of the new [PopochiuDialogMenuOption] in the game's graphic interface folder
	var game_dialog_menu_option: PackedScene = load(PopochiuResources.GUI_GAME_FOLDER.path_join(
		"components/dialog_menu/dialog_menu_option/dialog_menu_option.tscn"
	))
	
	# Assign the new [PopochiuDialogMenuOption] to the game's GUI dialog menu component and delete
	# any option inside its DialogOptionsContainer child
	var game_dialog_menu: PopochiuDialogMenu = load(GAME_DIALOG_MENU_PATH).instantiate()
	game_dialog_menu.option_scene = game_dialog_menu_option
	for opt in game_dialog_menu.get_node("ScrollContainer/DialogOptionsContainer").get_children():
		opt.owner = null
		opt.free()
	
	var done := PopochiuEditorHelper.pack_scene(game_dialog_menu)
	if done != OK:
		PopochiuUtils.print_error(
			"Couldn't update PopochiuDialogMenuOption reference in PopochiuDialogMenu"
		)
		return Completion.FAILED
	
	# Update the dependency to [PopochiuDialogMenuOption] in the game's graphic interface scene
	var game_gui: PopochiuGraphicInterface = load(PopochiuResources.GUI_GAME_SCENE).instantiate()
	game_gui.get_node("DialogMenu").option_scene = game_dialog_menu_option
	done = PopochiuEditorHelper.pack_scene(game_gui)
	if done != OK:
		PopochiuUtils.print_error(
			"Couldn't update PopochiuDialogMenuOption reference in PopochiuGraphicInterface"
		)
		return Completion.FAILED
	
	# Delete the old [dialog_menu_option.tscn] file
	done = DirAccess.remove_absolute(
		"res://game/gui/components/dialog_menu/dialog_menu_option.tscn"
	)
	if done != OK:
		PopochiuUtils.print_error(
			"Couldn't update PopochiuDialogMenuOption reference in PopochiuDialogMenu"
		)
		return Completion.FAILED
	
	return Completion.DONE


## Update the [code]SettingsBar[/code] GUI component in the 2-click Context-sensitive GUI template.
## Returns [constant Completion.DONE] if the component is updated, [constant Completion.IGNORED] if
## the game's GUI does not use the [code]SettingsBar[/code] GUI component or is already using the
## new version, [constant Completion.FAILED] otherwise.
func _update_simple_click_settings_bar() -> Completion:
	if not FileAccess.file_exists(GAME_SETTINGS_BAR_PATH):
		# The game's GUI does not use the SettingsBar GUI component
		return Completion.IGNORED
	
	var game_settings_bar: PanelContainer = load(GAME_SETTINGS_BAR_PATH).instantiate()
	var dialog_speed_button: TextureButton = game_settings_bar.get_node("Box/BtnDialogSpeed")
	
	if not dialog_speed_button.speed_options.is_empty():
		# The component is up to date with the beta-3 version
		return Completion.IGNORED
	
	var addons_settings_bar: PanelContainer = load(PopochiuResources.GUI_TEMPLATES_FOLDER.path_join(
		"simple_click/components/settings_bar/settings_bar.tscn"
	)).instantiate()
	
	# Store the speed options defined in the original component
	var speed_options := []
	for opt: TextSpeedOption in addons_settings_bar.get_node("Box/BtnDialogSpeed").speed_options:
		var option := TextSpeedOption.new()
		option.resource_name = opt.resource_name
		option.speed = opt.speed
		option.description = opt.description
		option.icon = load(opt.icon.resource_path.replace(
			PopochiuResources.GUI_TEMPLATES_FOLDER.path_join(
				"simple_click/components/settings_bar/sprites/"
			),
			"res://game/gui/components/settings_bar/sprites/"
		))
		
		speed_options.append(option)
	
	# Assign the options to the component in the game's graphic interface component and save the
	# SettingsBat scene
	dialog_speed_button.speed_options = speed_options
	var scene_updated := PopochiuEditorHelper.pack_scene(game_settings_bar)
	
	return Completion.DONE if scene_updated == OK else Completion.FAILED


## Remove visual helper nodes in all [PopochiuProp]s, [PopochiuHotspot]s, and [PopochiuCharacter]s.
func _remove_helper_nodes() -> Completion:
	var characters_paths := PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(
		PopochiuResources.CHARACTERS_PATH,
		["tscn"]
	)
	var props_and_hotspots_paths :=\
	PopochiuMigrationHelper.get_absolute_file_paths_for_file_extensions(
		PopochiuResources.ROOMS_PATH,
		["tscn"],
		["markers", "regions", "walkable_areas"]
	).filter(
		func (file_path: String) -> bool:
			return not "room_" in file_path
	)
	var popochiu_clickables := characters_paths + props_and_hotspots_paths
	var any_updated := PopochiuUtils.any_exhaustive(popochiu_clickables, _remove_helper_nodes_in)
	
	return Completion.DONE if any_updated else Completion.IGNORED


## Remove the [code]BaselineHelper[/code] and [code]WalkToHelper[/code] nodes in [param scene_path].
## Also remove the [code]DialogPos[/code] node if it is a [PopochiuCharacter]. Returns
## [constant Completion.DONE] if any node is removed, [constant Completion.IGNORED] otherwise.
func _remove_helper_nodes_in(scene_path: String) -> bool:
	# Load the scene ignoring cache so changes made in previous steps are taken into account
	var popochiu_clickable: PopochiuClickable = (
		ResourceLoader.load(scene_path, "", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	).instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	
	var was_scene_updated := false
	
	# ---- Remove the BaselineHelper and WalkToHelper nodes ----------------------------------------
	if _remove_node(popochiu_clickable, "BaselineHelper"):
		was_scene_updated = true
	
	if _remove_node(popochiu_clickable, "WalkToHelper"):
		was_scene_updated = true
	
	# ---- Remove the DialogPos node ---------------------------------------------------------------
	# TODO: Uncomment this once PR #241 is merged
	if popochiu_clickable is PopochiuCharacter and popochiu_clickable.has_node("DialogPos"):
		popochiu_clickable.dialog_pos = popochiu_clickable.get_node("DialogPos").position
		_remove_node(popochiu_clickable, "DialogPos")
		was_scene_updated = true
	
	if was_scene_updated and PopochiuEditorHelper.pack_scene(popochiu_clickable, scene_path) != OK:
			PopochiuUtils.print_error(
				"Couldn't remove helper nodes in [b]%s[/b]." % popochiu_clickable.script_name
			)
	
	return was_scene_updated


## Remove the node in [param parent] with the path [param node_path]. Returns [code]true[/code] if
## the node is removed, [code]false[/code] otherwise.
func _remove_node(parent: Node, node_path: NodePath) -> bool:
	if parent.has_node(node_path):
		var child: Node = parent.get_node(node_path)
		child.owner = null
		child.free()
		return true
	return false


## Replace calls to deprecated properties and methods:
## - [code]E.current_room[/code] by [code]R.current[/code].
## - [code]E.goto_room()[/code] by [code]R.goto_room()[/code].
## - [code]E.queue_camera_offset()[/code] by [code]E.camera.queue_change_offset()[/code].
## - [code]E.camera_offset()[/code] by [code]E.camera.change_offset()[/code].
## - [code]E.queue_camera_shake()[/code] by [code]E.camera.queue_shake()[/code].
## - [code]E.camera_shake()[/code] by [code]E.camera.shake()[/code].
## - [code]E.queue_camera_shake_bg()[/code] by [code]E.camera.queue_shake_bg()[/code].
## - [code]E.camera_shake_bg()[/code] by [code]E.camera.shake_bg()[/code].
## - [code]E.queue_camera_zoom()[/code] by [code]E.camera.queue_change_zoom()[/code].
## - [code]E.camera_zoom()[/code] by [code]E.camera.change_zoom()[/code].
## - [code]E.stop_camera_shake()[/code] by [code]E.camera.stop_shake()[/code].
## - [code]return super.get_runtime_room()[/code] by [code]return get_runtime_room()[/code].
## - [code]return super.get_runtime_character()[/code] by [code]return get_runtime_character()[/code].
## - [code]return super.get_item_instance()[/code] by [code]return get_item_instance()[/code].
## - [code]return E.get_dialog()[/code] by [code]return get_instance()[/code].
## Returns [constant Completion.DONE] if any replacement is done, [constant Completion.IGNORED]
## otherwise.
func _replace_deprecated() -> Completion:
	return Completion.DONE if PopochiuMigrationHelper.replace_in_scripts([
		{from = "E.current_room", to = "R.current"},
		{from = "E.goto_room(", to = "R.goto_room("},
		{from = "E.queue_camera_offset(", to = "E.camera.queue_change_offset("},
		{from = "E.camera_offset(", to = "E.camera.change_offset("},
		{from = "E.queue_camera_shake(", to = "E.camera.queue_shake("},
		{from = "E.camera_shake(", to = "E.camera.shake("},
		{from = "E.queue_camera_shake_bg(", to = "E.camera.queue_shake_bg("},
		{from = "E.camera_shake_bg(", to = "E.camera.shake_bg("},
		{from = "E.queue_camera_zoom(", to = "E.camera.queue_change_zoom("},
		{from = "E.camera_zoom(", to = "E.camera.change_zoom("},
		{from = "E.stop_camera_shake()", to = "E.camera.stop_shake()"},
		# autoloads
		{from = "return super.get_runtime_room(", to = "return get_runtime_room("},
		{from = "return super.get_runtime_character(", to = "return get_runtime_character("},
		{from = "return super.get_item_instance(", to = "return get_item_instance("},
		{from = "return E.get_dialog(", to = "return get_instance("},
	]) else Completion.IGNORED


## Update camera limit calculations for each room to utilize the new [member PopochiuRoom.width]
## and [member PopochiuRoom.height] properties.
func _update_rooms_sizes() -> Completion:
	var any_room_updated := PopochiuUtils.any_exhaustive(
		PopochiuEditorHelper.get_rooms(), _update_room_size
	)
	
	_reload_needed = any_room_updated
	return Completion.DONE if any_room_updated else Completion.IGNORED


## Updates the values of [member PopochiuRoom.width] and [member PopochiuRoom.height] in
## [param popochiu_room] based on the values of the deprecated camera limits properties.
func _update_room_size(popochiu_room: PopochiuRoom) -> bool:
	var viewport_width := ProjectSettings.get_setting(PopochiuResources.DISPLAY_WIDTH)
	var viewport_height := ProjectSettings.get_setting(PopochiuResources.DISPLAY_HEIGHT)
	
	# Calculate the width based on the camera limits
	var left := 0.0 if is_inf(popochiu_room.limit_left) else popochiu_room.limit_left
	var right := 0.0 if is_inf(popochiu_room.limit_right) else popochiu_room.limit_right
	var width: int = viewport_width - int(left)
	width += int(right) - viewport_width
	
	popochiu_room.width = maxi(width, viewport_width)
	
	# Calculate the height based on the camera limits
	var top := 0.0 if is_inf(popochiu_room.limit_top) else popochiu_room.limit_top
	var bottom := 0.0 if is_inf(popochiu_room.limit_bottom) else popochiu_room.limit_bottom
	var height: int = viewport_height - int(top)
	height += int(bottom) - viewport_height
	
	popochiu_room.height = maxi(height, viewport_height)
	
	if PopochiuEditorHelper.pack_scene(popochiu_room) != OK:
		PopochiuUtils.print_error(
			"Migration 2: Couldn't update the [code]width[/code] and [code]height[/code] of" +\
			" [b]%s[/b] room." % popochiu_room.script_name
		)
		return false
	
	return true


#endregion
