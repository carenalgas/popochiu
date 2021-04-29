# TODO: Crear un icono para este tipo de nodos
tool
class_name Room
extends Node2D
# Nodo base para la creación de habitaciones dentro del juego.

# TODO: Tal vez estas podrían reducirse a dos señales: item_interacted y item_looked.
# Y los Props y Hotspots podrían heredar de Item.
signal prop_interacted(prop, msg)
signal prop_looked(prop, msg)
signal hotspot_interacted(hotspot)
signal hotspot_looked(hotspot)

export var script_name := ''
export(Array, Dictionary) var characters := [] setget _set_characters
export var has_player := true

var _path := []

onready var _nav_path: Navigation2D = $WalkableAreas.get_child(0)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos de Godot ░░░░
func _ready():
	for p in $Props.get_children():
		# TODO: Esta validación de baseline no será necesaria cuando sean Props
		if p.get('baseline'):
			var prop: Prop = p as Prop
			prop.connect('interacted', self, '_on_prop_interacted', [p])
			prop.connect('looked', self, '_on_prop_looked', [p])
	
	for h in $Hotspots.get_children():
		var hotspot: Hotspot = h
#		hotspot.connect(
#			'interacted', self, 'emit_signal', ['hotspot_interacted', hotspot]
#		)
		hotspot.connect('looked', self, '_hotspot_looked', [hotspot])
	
	if not Engine.editor_hint:
		C.player.connect('started_walk_to', self, '_update_navigation_path')
		for c in $Characters.get_children():
			(c as Node2D).queue_free()
		E.room_readied(self)


func _process(delta):
	if Engine.editor_hint or not is_instance_valid(C.player) or _path.empty():
		return

	var walk_distance = C.player.walk_speed * delta
	_move_along_path(walk_distance)


func _unhandled_input(event):
	if not has_player: return
	if not event.is_action_pressed('interact'):
		if event.is_action_released('look'):
			if I.active: I.set_active_item()
		return

	C.player.walk(get_local_mouse_position(), false)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos públicos ░░░░
func get_walkable_area() -> Navigation2D:
	return $WalkableAreas.get_child(0) as Navigation2D


func character_moved(chr: Character) -> void:
	for p in $Props.get_children():
		if p is Prop:
			var prop: Node2D = p
			var baseline: float = prop.to_global(Vector2.DOWN * prop.baseline).y
			if baseline > chr.global_position.y:
				p.z_index = 1
			else:
				p.z_index = 0


# Aquí es donde se deben cargar los personajes de la habitación para que sean
# renderizados en el juego.
func on_room_entered() -> void:
	pass


func on_room_transition_finished() -> void:
	pass


func add_character(chr: Character) -> void:
	$Characters.add_child(chr)


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _move_along_path(distance):
	var last_point = C.player.position
	
	while _path.size():
		var distance_between_points = last_point.distance_to(_path[0])
		if distance <= distance_between_points:
			C.player.position = last_point.linear_interpolate(
				_path[0], distance / distance_between_points
			)

			character_moved(C.player)

			return

		distance -= distance_between_points
		last_point = _path[0]
		_path.remove(0)

	C.player.position = last_point
	C.player.idle(false)
	C.emit_signal('character_move_ended', C.player)

	set_process(false)


func _update_navigation_path(start_position, end_position):
	_path = _nav_path.get_simple_path(start_position, end_position, true)
	_path.remove(0)
	set_process(true)


func _on_prop_interacted(msg: String, prop: Prop) -> void:
	_update_navigation_path(C.player.position, prop.walk_to_point)
#	emit_signal('prop_interacted', prop, msg)


func _on_prop_looked(msg: String, prop: Prop) -> void:
	var text: String = 'Eso es un prop de la habitación y se llama: %s' % prop.description.to_lower()
	if msg:
		text = msg
	C.emit_signal('character_spoke', C.player, text)
#	emit_signal('prop_looked', prop, msg)


func _hotspot_looked(hotspot: Hotspot) -> void:
	G.emit_signal(
		'show_box_requested',
		'Estás viendo: %s' % hotspot.description
	)


func _set_characters(value: Array) -> void:
	characters = value
	for v in value.size():
		if not value[v]:
			characters[v] = {
				script_name = '',
				position = Vector2.ZERO
			}
			property_list_changed_notify()
