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
			yield(E.run([
				'Popsy: Hi!'
			]), 'completed')
			
			opt.turn_off_forever()
			turn_on_options(['How'])
		'How':
			if opt.used_times == 1:
				yield(E.run([
					'Popsy: Fine. Thanks!'
				]), 'completed')
			else:
				yield(E.run([
					'Popsy: ...',
					'Popsy: You already asked that......',
				]), 'completed')
			
			turn_on_options(['Opt1'])
		_:
			# By default close the dialog
			stop()
	
	_show_options()
