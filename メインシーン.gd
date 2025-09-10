extends Node2D

@onready var accept_dialog = $AcceptDialog
@onready var confirmation_dialog = $ConfirmationDialog

func _ready() -> void:
	randomize()
	Global.deck_creator(Global.enemy_deck)
	Global.battle_stage = Global.Stage.PLAIN # 草原しかないのでとりあえず
	$version.text = "[i]%s [/i]" % Global.VERSION_TEXT


func _on_button_pressed():
	# 定義したシーンに切り替え
	get_tree().change_scene_to_file(Global.deck_scene)


func _on_debug_button_up():
	get_tree().change_scene_to_file(Global.debug_scene)

## セーブデータ削除確認画面表示
func _on_reset_button_up() -> void:
	confirmation_dialog.panel_color = Color.RED
	confirmation_dialog.display_dialog(
		"本当にセーブデータを削除しますか？\n削除したデータは二度と復元できません！", 
		"セーブデータ削除")

## セーブデータ削除
func _on_confirmation_dialog_confirmed() -> void:
	var path: String ## セーブデータファイルパス
	if Global.VERSION_BETA == true:
		path = "user://savedata_beta.txt" # β版専用
	else:
		path = "user://savedata.txt"
	
	if FileAccess.file_exists(path):
		var err := DirAccess.remove_absolute(path)
		
		if err != OK:
			print("ERROR:セーブデータの削除に失敗しました: %s" % err)
		else:
			print("セーブデータを削除しました")
			Global.load_game() # 新規セーブデータ作成
	else:
		print("ERROR:セーブデータが存在しません: %s" % path)
