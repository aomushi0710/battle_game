extends Button

func _on_button_up():
	get_tree().change_scene_to_file(Global.chara_scene)
