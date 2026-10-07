extends Node2D

@onready var version_label := %Version as RichTextLabel

func _ready() -> void:
	randomize()
	Global.enemy_deck.deck_creator(false)
	var version_text: String = ""
	if Global.VERSION_BETA:
		version_text += "β "
	version_label.text = version_text + "[i]ver.%s[/i]" % Global.version


func _on_button_pressed():
	get_tree().change_scene_to_file(Global.map_scene)


func _on_debug_button_up():
	get_tree().change_scene_to_file(Global.debug_scene)

## セーブデータ削除確認画面表示
func _on_reset_button_up() -> void:
	var selected_index: int = await DialogManager.set_dialog(preload("res://resource/dialog_data/main/delete_save_data_1.tres"))
	if selected_index == 1:
		SaveManager.delete_game()
		await DialogManager.set_dialog(preload("res://resource/dialog_data/main/delete_save_data_2.tres"))
		await DialogManager.set_dialog(preload("res://resource/dialog_data/save_manager/create_new_save_data.tres"))
	
	DialogManager.hide_dialog()
	
