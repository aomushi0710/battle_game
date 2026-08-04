extends Node2D

func _ready() -> void:
	randomize()
	Global.enemy_deck.deck_creator(false)
	var version_text: String = ""
	if Global.VERSION_BETA:
		version_text += "β "
	$version.text = version_text + "[i]ver.%s[/i]" % Global.version


func _on_button_pressed():
	get_tree().change_scene_to_file(Global.map_scene)


func _on_debug_button_up():
	get_tree().change_scene_to_file(Global.debug_scene)

## セーブデータ削除確認画面表示
func _on_reset_button_up() -> void:
	var test = Global.confirmation_dialog
	print(test)
	Global.confirmation_dialog.on_confirm_callable = self._on_confirmed
	var test2 = test.on_confirm_callable
	print(test2)
	Global.confirmation_dialog.panel_color = Color.RED
	Global.confirmation_dialog.display_dialog(
		"本当にセーブデータを削除しますか？\n削除したデータは二度と復元できません！", 
		"セーブデータ削除")

## セーブデータ削除
func _on_confirmed() -> void:
	var path: String ## セーブデータファイルパス
	if Global.VERSION_BETA == true:
		path = Global.save_data_path_beta
	else:
		path = Global.save_data_path
	
	SaveManager.delete_file(path)
	SaveManager.load_game() # 新規セーブデータ作成
