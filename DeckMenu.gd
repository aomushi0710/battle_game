extends Control

const deck_size: int = 3 ## デッキのサイズ

@onready var parent := $".."
@onready var lineedit := $Deck/LineEdit
@onready var monster_icons := $Deck/MonsterIcons
@onready var monster_names := $Deck/Names

var max_evolution_form: Monster.Form ## デッキのモンスターで最大の進化形態
## デッキ編成で現在表示中のモンスターの形態。[br]
## 値を変更すると自動で[code]update()[/code]関数を呼び、デッキ編成の見た目を変更します。
var preview_form: Monster.Form:
	set(form):
		preview_form = form
		update()


func on_mode_entered() -> void:
	parent._on_option_button_item_selected(Monster.Form.第一形態)


func update() -> void:
	lineedit.text = Global.player_deck.name
	for i in range(deck_size):
		## [DeckMonster]型で、モンスターが存在するかの確認とレベルの取得に用いる
		var deck_monster := Global.player_deck.monster[i]
		
		if deck_monster.monster == null:
			monster_icons.get_child(i).monster = null
			monster_names.get_child(i).text = " \n "
		else:
			## [Monster]型で、各形態の情報の取得に用いる
			var monster: Monster
			# preview_formの形態を持たないモンスターはモンスターの持つ最後の形態で表示される
			if deck_monster.evolution_forms.size() > preview_form:
				monster = deck_monster.evolution_forms[preview_form]
			else:
				monster = deck_monster.evolution_forms[-1]
			
			monster_icons.get_child(i).monster = monster
			monster_names.get_child(i).text = "[i]Lv.%2d[/i]\n[b]%s[/b]" % \
			[deck_monster.level, monster.name]
		
		if deck_monster.evolution_forms.size() - 1 > max_evolution_form:
			max_evolution_form = deck_monster.evolution_forms.size() - 1
	
	var preview_button: OptionButton = parent.evolution_preview_button
	# 全てのモンスターがnullの時
	if Global.player_deck.monster.all(func(mon): return mon.monster == null):
		# ALERT [param preview_form]に代入するとsetterによって再びこの関数が呼ばれる
		# ので、無限ループを防止すること
		if preview_form != Monster.Form.第一形態:
			parent._on_option_button_item_selected(Monster.Form.第一形態)
		
		preview_button.disabled = true
	else:
		# 足りない形態の分だけ選択肢を追加する
		for i in range(max_evolution_form + 1):
			if preview_button.get_selectable_item(true) < i:
				preview_button.add_item(Monster.form_names[i], i)
		
		preview_button.disabled = false
	
	## 余分な選択肢を削除する回数
	var delete_count: int = preview_button.get_item_count() - max_evolution_form - 1
	for i in max(0, delete_count):
		preview_button.remove_item(preview_button.get_selectable_item(true))


func _on_save_button_up() -> void:
	Global.deck_name = lineedit.text
	Global.save_mode = true
	get_tree().change_scene_to_file(Global.deck_save_scene)


func _on_load_button_up() -> void:
	Global.save_mode = false
	get_tree().change_scene_to_file(Global.deck_save_scene)


func _on_auto_fill_button_up() -> void:
	Global.player_deck.deck_creator()
	parent._on_option_button_item_selected(Monster.Form.第一形態)


func _on_reset_button_up() -> void:
	Global.confirmation_dialog.on_confirm_callable = self._on_confirmed
	Global.confirmation_dialog.display_dialog(
		"現在選択中のデッキデータをリセットしようとしています。\nよろしいですか？\n" + 
		"※セーブデータは削除されません。", "リセット確認")


func _on_confirmed() -> void:
	Global.player_deck = Deck.new()
	parent._on_option_button_item_selected(Monster.Form.第一形態)
	Global.accept_dialog.display_dialog(
			"デッキデータをリセットしました。", 
			"リセット完了"
	)
