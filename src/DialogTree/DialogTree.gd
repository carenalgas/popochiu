tool
class_name DialogTree
extends Resource

export var options := [] setget _set_options
export var script_name := ''


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos virtuales ░░░░
func start() -> void:
	_show_options()
	yield(D, 'dialog_finished')


func option_selected(opt: Dictionary) -> void:
	pass


# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ métodos privados ░░░░
func _show_options() -> void:
	D.emit_signal('dialog_requested', options)
	if not D.is_connected('option_selected', self, 'option_selected'):
		D.connect('option_selected', self, 'option_selected')


func _set_options(value: Array) -> void:
	var last_size := options.size()
	options = value
	
	# TODO: Que estas opciones sean un DialogOption.gd (no de los que se muestran
	# en la interfaz gráfica, sino uno como el de Power Quest:
	# http://www.powerhoof.com/public/powerquestdocs/interface_power_tools_1_1_quest_1_1_i_dialog_option.html
	if last_size > options.size():
		options[options.size() - 1] = {
			id = '%d' % options.size(),
			text = 'Option %d' % options.size(),
			visible = true
		}
		property_list_changed_notify()
