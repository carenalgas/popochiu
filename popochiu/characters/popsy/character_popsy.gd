@tool
extends PopochiuCharacter
# You can use E.queue([]) to trigger a sequence of events.
# Use await E.queue([]) if you want to pause the excecution of
# the function until the sequence of events finishes.

const Data := preload('character_popsy_state.gd')

var state: Data = load('res://popochiu/characters/popsy/character_popsy.tres')


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
# When the room in which this node is located finishes being added to the tree
func _on_room_set() -> void:
	pass


# When the node is clicked
func _on_click() -> void:
	A.vo_goddiu_01.play()
#	D.ChatWithPopsy.start()


# When the node is right clicked
func _on_right_click() -> void:
	var op: PopochiuDialogOption = await D.show_inline_dialog([
		'Hi', 'Hola', 'Ciao'
	])

	match int(op.id): # You can compare the String if you prefer
		0:
			C.Goddiu.say("How is it going?")
		1:
			C.Goddiu.say("¿Cómo te va?")
		2:
			C.Goddiu.say("Come sta andando?")


# When the node is clicked and there is an inventory item selected
func _on_item_used(item: PopochiuInventoryItem) -> void:
	if item.script_name == 'ToyCar':
		await C.Goddiu.say('Take this')
		await I.ToyCar.remove()
		await C.Popsy.say('Thanks!')


# Use it to play the idle animation for the character
func _play_idle() -> void:
	pass


# Use it to play the walk animation for the character
# target_pos can be used to know the movement direction
func _play_walk(target_pos: Vector2) -> void:
	super(target_pos)


# Use it to play the talk animation for the character
func _play_talk() -> void:
	pass


# Use it to play the grab animation for the character
func _play_grab() -> void:
	pass
