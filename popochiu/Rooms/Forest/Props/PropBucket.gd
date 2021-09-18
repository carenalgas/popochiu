tool
extends Prop

var _interacted := false


func on_interact() -> void:
	Globals.game_progress.append(Globals.GameState.GOT_BUCKET)
	
	yield(E.run([
		C.walk_to_clicked(),
		C.player.face_down(),
		'Player: Uy. Un balde re-áspero',
		E.wait(0.2),
		A.play({cue_name = 'bucket_01'}),
		disable(),
		I.add_item('Bucket'),
		'Player: ¡Ora sí! Ya verán de lo que soy capaz.',
		'Barney: ¡Cállese maricón!'
	]), 'completed')
	
	queue_free()


func on_look() -> void:
	yield(E.run([
		'Dave: Es un balde ahí de lo más normal y puerco.'
	]), 'completed')
	G.done()
