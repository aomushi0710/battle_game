extends Control

@export var player_deck_slot: DeckSlot
@export var container: VBoxContainer

func _ready() -> void: # デッキスロットインスタンス生成
	player_deck_slot.deck_name_label.text = Global.player_deck.name
	player_deck_slot.monster_icon_1.data = Global.player_deck.monster[0].data
	player_deck_slot.monster_icon_2.data = Global.player_deck.monster[1].data
	player_deck_slot.monster_icon_3.data = Global.player_deck.monster[2].data
	var beta_text: String = ""
	if Global.VERSION_BETA:
		beta_text = "(β)"
	player_deck_slot.version_label.text = (
		"  [i]ver.%s%s[/i]" % [Global.version, beta_text]
	)
	
	for i in range(1, 10):
		var deck_slot: DeckSlot = preload("res://scene/component/deck_slot.tscn").instantiate()
		deck_slot.slot = i # デッキスロット番号 連番
		deck_slot.deck_slot_label.text = "デッキスロット%d" % i
		deck_slot.save_button.button_up.connect(func():
			SaveManager.save_deck(i)
			setting()
		)
		deck_slot.load_button.button_up.connect(func():
			SaveManager.load_deck(i)
			setting()
		)
		deck_slot.reset_button.button_up.connect(func():
			delete_deck(i)
			setting()
		)
		deck_slot.setting(SaveManager.load_file("user://deck_slot_%d.txt" % i))
		
		container.add_child(deck_slot)


func _on_戻る_button_up() -> void:
	get_tree().change_scene_to_file(Global.select_scene)


func delete_deck(slot: int) -> void:
	Global.confirmation_dialog.on_confirm_callable = \
	self._on_confirmed.bind(slot)
	Global.confirmation_dialog.display_dialog(
			"デッキスロット%dのデータを削除しようとしています。\nよろしいですか？" % slot, 
			"⚠️削除確認⚠️"
	)


func _on_confirmed(slot: int) -> void:
	SaveManager.delete_file("user://deck_slot_%d.txt" % slot)
	setting()
	Global.accept_dialog.display_dialog(
			"デッキスロット%dのデータを削除しました。" % slot, 
			"削除完了"
	)

## 現在のデッキとセーブスロットのデッキを読み込んで表示する関数
func setting() -> void:
	player_deck_slot.deck_name_label.text = Global.player_deck.name
	player_deck_slot.monster_icon_1.data = Global.player_deck.monster[0].data
	player_deck_slot.monster_icon_2.data = Global.player_deck.monster[1].data
	player_deck_slot.monster_icon_3.data = Global.player_deck.monster[2].data
	var beta_text: String = ""
	if Global.VERSION_BETA:
		beta_text = "(β)"
	player_deck_slot.version_label.text = (
		"  [i]ver.%s%s[/i]" % [Global.version, beta_text]
	)
	for i in range(container.get_child_count()): # 全てのデッキスロットに対して
		container.get_child(i).setting(
			SaveManager.load_file("user://deck_slot_%d.txt" % (i + 1))
		) # ロードし直す
