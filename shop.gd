extends Control

func _ready() -> void:
	$coin.text = "[img=50]res://image/coin.PNG[/img] [color=gold]%d[/color]" % Global.coin


func _on_戻る_button_up() -> void:
	get_tree().change_scene_to_packed(Global.deck_scene)
