@tool
extends PopochiuDialog


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ VIRTUAL ░░░░
func on_start() -> void:
	await E.run([])


func option_selected(opt: PopochiuDialogOption) -> void:
	# Use match to check which option was selected and excecute something for
	# each one
	await D.say_selected()
	
	match opt.id:
		'Opt1':
			await E.run([
				'Popsy: Hi!'
			])

			opt.turn_off_forever()
			turn_on_options(['Opt2'])
		'Opt2':
			if opt.used_times == 1:
				await E.run([
					'Popsy: Fine. Thanks!'
				])
			else:
				await E.run([
					'Popsy: ...',
					'Popsy: You already asked that......',
				])

			turn_on_options(['Opt1'])
		_:
			# By default close the dialog
			stop()
	
	_show_options()
