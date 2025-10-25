extends Control

@onready var lineedit := $Party/LineEdit
@onready var monster_icons := $Party/MonsterIcons
@onready var monster_names := $Party/Names


func on_mode_entered() -> void:
	update()


func update() -> void:
	lineedit.text = Global.player_deck.name
	for i in range(3):
		var deck_monster := Global.player_deck.monster[i]
		monster_icons.get_child(i).monster = deck_monster.monster
		if deck_monster.monster == null:
			monster_names.get_child(i).text = " \n "
		else:
			monster_names.get_child(i).text = "[i]Lv.%2d[/i]\n[b]%s[/b]" % \
			[deck_monster.level, deck_monster.monster.name]


func _on_save_button_up() -> void:
	Global.deck_name = lineedit.text
	Global.save_mode = true
	get_tree().change_scene_to_file(Global.deck_save_scene)


func _on_load_button_up() -> void:
	Global.save_mode = false
	get_tree().change_scene_to_file(Global.deck_save_scene)


func _on_auto_fill_button_up() -> void:
	Global.player_deck.deck_creator()
	update()


func _on_reset_button_up() -> void:
	Global.confirmation_dialog.on_confirm_callable = self._on_confirmed
	Global.confirmation_dialog.display_dialog(
		"現在選択中のデッキデータをリセットしようとしています。\nよろしいですか？\n" + 
		"※セーブデータは削除されません。", "リセット確認")


func _on_confirmed() -> void:
	Global.player_deck = Deck.new()
	update()
	Global.accept_dialog.display_dialog(
			"デッキデータをリセットしました。", 
			"リセット完了"
	)
