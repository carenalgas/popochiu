tool
extends PopochiuCharacter
# You can use E.run([]) to trigger a sequence of events.
# Use yield(E.run([]), 'completed') if you want to pause the excecution of
# the function until the sequence of events finishes.

const Data := preload('CharacterPopsyState.gd')

var state: Data = preload('CharacterPopsy.tres')

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
# When the node is clicked
func on_interact() -> void:
	D.TestA.start()
	
#	if state.is_hungry:
#		state.is_hungry = false
#		E.run([
#			'Goddiu: ¡oñiiii mi pepechí!',
#			'Popsy: ¡Tengo hambre!'
#		])
#	else:
#		E.run([
#			'Goddiu: ¡oñiiii mi pepechí!',
#			'Popsy: oñiiiiiiiiiiiiiii',
#			'Popsy: Ya me comí un ' + state.wants
#		])


# When the node is right clicked
func on_look() -> void:
	E.run([walk_to_prop('ToyCar')])


# When the node is clicked and there is an inventory item selected
func on_item_used(_item: PopochiuInventoryItem) -> void:
	E.run([
		C.walk_to_clicked(),
		C.face_clicked(),
		'Player: Take this',
		I.remove_item('ToyCar', true, false),
		'Popsy[2]: Oh...',
		'...',
		'Popsy: Thanks',
	])


# Use it to play the idle animation for the character
func play_idle() -> void:
	pass


# Use it to play the walk animation for the character
# target_pos can be used to know the movement direction
func play_walk(target_pos: Vector2) -> void:
	.play_walk(target_pos)


# Use it to play the talk animation for the character
func play_talk() -> void:
	pass


# Use it to play the grab animation for the character
func play_grab() -> void:
	pass

