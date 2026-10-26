class_name MapMenu
extends Control

signal toggled(is_open: bool)

@onready var help_label := %ScrollingLabel as ScrollingLabel

func _ready() -> void:
	help_label.connect_hover_signal(self)


func open_menu() -> void:
	show()
	toggled.emit(true)


func close_menu() -> void:
	hide()
	toggled.emit(false)


func _on_monster_button_up() -> void:
	SceneManager.change_scene(
		Global.SELECT_SCENE,
		SceneManager.fade_out_zoom,
		SceneManager.fade_in_transparent
	)


func _on_shop_button_up() -> void:
	SceneManager.change_scene(
		Global.SHOP_SCENE,
		SceneManager.fade_out_zoom,
		SceneManager.fade_in_transparent
	)


func _on_save_button_up() -> void:
	SaveManager.save_game()
	await DialogManager.set_dialog(preload("res://resource/dialog_data/common/save_complete.tres"))
	DialogManager.hide_dialog()


func _on_title_button_up() -> void:
	## TODO タイトル画面実装後に変更
	get_tree().change_scene_to_file(Global.MAIN_SCENE)


func _on_close_button_up() -> void:
	pass # Replace with function body.
