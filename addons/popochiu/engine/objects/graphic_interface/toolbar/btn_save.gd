extends 'toolbar_button.gd'


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PUBLIC ░░░░
func on_pressed() -> void:
	G.show_save(format_date(Time.get_datetime_dict_from_system()))


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ PRIVATE ░░░░
func format_date(date: Dictionary) -> String:
	return '%d/%02d/%02d %02d:%02d:%02d' % [
		date.year, date.month, date.day, date.hour, date.minute, date.second
	]
