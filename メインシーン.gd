extends Node2D

func _ready() -> void:
	randomize()
	Global.enemy_deck.deck_creator()
	Global.battle_stage = Global.Stage.PLAIN # 草原しかないのでとりあえず
	var version_text: String = ""
	if Global.VERSION_BETA:
		version_text += "β "
	$version.text = version_text + "[i]ver.%s[/i]" % \
	ProjectSettings.get_setting("application/config/version")
	
	ConfirmationDialogManager.confirmed.connect(_on_confirmed)


func _exit_tree() -> void:
	ConfirmationDialogManager.confirmed.disconnect(_on_confirmed)
	

func _on_button_pressed():
	# 定義したシーンに切り替え
	get_tree().change_scene_to_file(Global.deck_scene)


func _on_debug_button_up():
	get_tree().change_scene_to_file(Global.debug_scene)

## セーブデータ削除確認画面表示
func _on_reset_button_up() -> void:
	ConfirmationDialogManager.panel_color = Color.RED
	ConfirmationDialogManager.display_dialog(
		"本当にセーブデータを削除しますか？\n削除したデータは二度と復元できません！", 
		"セーブデータ削除")

## セーブデータ削除
func _on_confirmed() -> void:
	var path: String ## セーブデータファイルパス
	if Global.VERSION_BETA == true:
		path = Global.save_data_path_beta
	else:
		path = Global.save_data_path
	
	if FileAccess.file_exists(path):
		var err := DirAccess.remove_absolute(path)
		
		if err != OK:
			print("ERROR:セーブデータの削除に失敗しました: %s" % err)
		else:
			print("セーブデータを削除しました")
			Global.load_game() # 新規セーブデータ作成
	else:
		print("ERROR:セーブデータが存在しません: %s" % path)
