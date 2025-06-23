extends Node2D

func _ready() -> void:
	randomize()
	Global.deck_creator(Global.enemy_deck)
	Global.battle_stage = Global.Stage.PLAIN # 草原しかないのでとりあえず
	$version.text = "[i]%s [/i]" % Global.VERSION_TEXT


func _on_button_pressed():
	# 定義したシーンに切り替え
	get_tree().change_scene_to_packed(Global.deck_scene)


func _on_debug_button_up():
	get_tree().change_scene_to_packed(Global.debug_scene)
