extends Control

@export var score := 0
@export var max_score := 100

@onready var lbl_game_name: Label = %LblGameName
@onready var lbl_score: Label = %LblScore


#region Public #####################################################################################
func set_game_name(game_name: String) -> void:
	lbl_game_name.text = game_name


func reset_score() -> void:
	score = 0
	_update_text()


func add_score(value: int) -> void:
	score += value
	_update_text()


func subtract_score(value: int) -> void:
	score -= value
	_update_text()


#endregion

#region Private ####################################################################################
func _update_text() -> void:
	lbl_score.text = "%d/%d" % [score, max_score]


#endregion
