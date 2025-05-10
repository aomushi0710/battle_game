extends Node2D

func _on_button_pressed():
	# 定義したシーンに切り替え
	get_tree().change_scene_to_packed(Global.deck_scene)
	


func _on_debug_button_up():
	get_tree().change_scene_to_packed(Global.debug_scene)
