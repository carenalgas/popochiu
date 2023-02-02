tool
extends PopochiuDialog


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func on_start() -> void:
	yield(E.get_tree(), 'idle_frame')


func option_selected(opt: PopochiuDialogOption) -> void:
	# Use match to check which option was selected and excecute something for
	# each one
	yield(D.say_selected(), 'completed')
	
	match opt.id:
		'Hi':
			yield(_opt_Hi(opt), 'completed')
		'How':
			yield(_opt_How(opt), 'completed')
		'Exit':
			# By default close the dialog
			stop()
	
	_show_options()


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func _opt_Hi(opt: PopochiuDialogOption) -> void:
	yield(E.run([
		'Popsy: Hi!'
	]), 'completed')
	
	opt.turn_off_forever()
	turn_on_options(['How'])


func _opt_How(opt: PopochiuDialogOption) -> void:
	if opt.used_times == 1:
		yield(E.run([
			'Popsy: Fine. Thanks!',
			'Popsy: How are you?',
		]), 'completed')
		
		var selection: PopochiuDialogOption = yield(
			D.show_inline_dialog([
				"I'm fine",
				"I would prefer to be death",
				"What do you care?",
			]), 'completed'
		)
		
		match selection.id:
			'Opt1':
				yield(E.run([
					"Player: Life is good",
					"Popsy: Yes it is"
				]), 'completed')
			'Opt2':
				yield(E.run([
					"Player: Life sucks",
					"Popsy: Not for me!",
					"Popsy: I'm a [wave]babyyyyyyy[/wave]",
				]), 'completed')
			'Opt3':
				yield(E.run([
					"Player: Who cares?",
					"Popsy: I do",
					"Popsy: Your my bigger brother",
					"Player: oooowwwwwww",
				]), 'completed')
	else:
		yield(E.run([
			'Popsy: ...',
			'Popsy: You already asked that......',
		]), 'completed')
