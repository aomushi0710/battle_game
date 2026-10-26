extends Node2D

@onready var version_label := %Version as RichTextLabel

func _ready() -> void:
	randomize()
	Global.enemy_deck.deck_creator(false)
	var version_text: String = ""
	if Global.IS_BETA:
		version_text += "β "
	version_label.text = version_text + "[i]ver.%s[/i]" % Global.version


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file(Global.MAP_SCENE)


func _on_debug_button_up() -> void:
	get_tree().change_scene_to_file(Global.DEBUG_SCENE)

## セーブデータ削除確認画面表示
func _on_reset_button_up() -> void:
	var selected_index: int = await DialogManager.set_dialog(preload("res://resource/dialog_data/main/delete_save_data_1.tres"))
	if selected_index == 1:
		SaveManager.delete_game()
		await DialogManager.set_dialog(preload("res://resource/dialog_data/main/delete_save_data_2.tres"))
		await DialogManager.set_dialog(preload("res://resource/dialog_data/save_manager/create_new_save_data.tres"))
	
	tween.tween_property(_ui, "modulate:a", 0.0, 1.0).from(1.0)
	await tween.finished


func _on_continue_button_up() -> void:
	_change_to_map_scene()


func _on_new_game_button_up() -> void:
	if SaveManager.is_new_data:
		_change_to_map_scene()
	else:
		var selected_index: int = await DialogManager.set_dialog(preload("res://resource/dialog_data/main/delete_save_data_1.tres"))
		if selected_index == 1:
			SaveManager.delete_game()
			
			await DialogManager.set_dialog(preload("res://resource/dialog_data/main/delete_save_data_2.tres"))
			DialogManager.hide_dialog()
			
			_change_to_map_scene()
		else:
			DialogManager.hide_dialog()


func _on_credit_button_up() -> void:
	await DialogManager.set_dialog(preload("res://resource/dialog_data/main/credit.tres"))
	DialogManager.hide_dialog()


func _change_to_map_scene() -> void:
	SceneManager.block_input()
	await _hide_title_animation()
	SceneManager.change_scene(Global.MAP_SCENE, SceneManager.no_fade_out, SceneManager.no_fade_in)
