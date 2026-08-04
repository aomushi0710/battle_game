extends Control

@export var help_label: ScrollingLabel

func _ready() -> void:
	help_label.connect_hover_signal(self)


func _on_monster_button_up() -> void:
	get_tree().change_scene_to_file(Global.select_scene)


func _on_shop_button_up() -> void:
	get_tree().change_scene_to_file(Global.shop_scene)


func _on_save_button_up() -> void:
	SaveManager.save_game()
	Global.accept_dialog.display_dialog("セーブが完了しました！", "✅セーブ完了✅")


func _on_title_button_up() -> void:
	get_tree().change_scene_to_file(Global.main_scene)
