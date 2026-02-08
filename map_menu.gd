extends Control


func _on_monster_button_up() -> void:
	get_tree().change_scene_to_file(Global.select_scene)


func _on_shop_button_up() -> void:
	get_tree().change_scene_to_file(Global.shop_scene)


func _on_title_button_up() -> void:
	get_tree().change_scene_to_file(Global.main_scene)
