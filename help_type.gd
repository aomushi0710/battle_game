extends Button

func _on_toggled(toggled_on):
	if toggled_on == true:
		$ColorRect.show()
		get_tree().paused = true
	else:
		$ColorRect.hide()
		get_tree().paused = false

func _on_monster_help_button_up(): # モンスターについてのヘルプメニューを開く
	#$ColorRect/help_player.hide()
	$ColorRect/help_label.hide()
	$ColorRect/monster_help.hide()
	$ColorRect/monster_help_menu.show()

func _on_help_back_button_up(): # 上記メニューを閉じる
	$ColorRect/monster_help_menu.hide()
	#$ColorRect/help_player.show()
	$ColorRect/help_label.show()
	$ColorRect/monster_help.show()

func _on_help_back_monster_button_up(): # 各種ページを閉じ、上記メニューに戻る
	$ColorRect/monster_help_page.hide()
	$ColorRect/monster_help_menu.show()


func _on_type_button_up():
	$ColorRect/monster_help_menu.hide()
	$ColorRect/monster_help_page/monster_help_label.text = Global.help_message["type"]
	$ColorRect/monster_help_page.show()


func _on_status_button_up():
	$ColorRect/monster_help_menu.hide()
	$ColorRect/monster_help_page/monster_help_label.text = Global.help_message["status"]
	$ColorRect/monster_help_page.show()
