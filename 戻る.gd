extends Button

func _on_button_up():
	get_tree().change_scene_to_packed(Global.chara_scene)
