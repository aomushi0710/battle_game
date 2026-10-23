class_name MapMenu
extends Control

@onready var help_label := %ScrollingLabel as ScrollingLabel

func _ready() -> void:
	help_label.connect_hover_signal(self)


func _on_monster_button_up() -> void:
	get_tree().change_scene_to_file(Global.SELECT_SCENE)


func _on_shop_button_up() -> void:
	get_tree().change_scene_to_file(Global.SHOP_SCENE)


func _on_save_button_up() -> void:
	SaveManager.save_game()
	await DialogManager.set_dialog(preload("res://resource/dialog_data/common/save_complete.tres"))
	DialogManager.hide_dialog()


func _on_title_button_up() -> void:
	get_tree().change_scene_to_file(Global.MAIN_SCENE)
