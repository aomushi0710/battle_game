extends Control

## 親の[member MenuMonster.selected_monster]変数に代入させるシグナル。[br]
## 返り値とするリソース[Monster]は必ず、複製した独立しているものを指定する。
signal selected_monster_changed(monster: Monster)
signal get_selected_slot_index

const HCONTAINER_LIMIT: int = 4 ## モンスターボタンを横に並べられる限界の個数

## [signal get_selected_slot_index]によって親から得られたindexを格納する変数
var _selected_slot_index: int
var now_monster_id: int ## status関数、同じモンスターかどうかの検出用


@export var parent: MenuMonster
@export var evolution_preview_button: OptionButton

@export var monster_containers: VBoxContainer

func _on_戻る_button_up():
	get_tree().change_scene_to_file(Global.deck_scene)

## モンスターの数だけボタンを生成する関数
func _ready() -> void:
	for i in len(Global.monster_data):
		var button: MonsterIcon = Global.monster_icon.instantiate()
		
		button.data = Global.monster_data[i]
		button.form = Global.Form.第一形態
		button.button_up.connect(func():
			var monster: Monster ## [signal selected_monster_changed]の引数
			## デッキに登録されているモンスターIDの配列。モンスターがいない時は-1。
			var deck_monster_ids := Global.player_deck.monster.map(
				func(m):
					if m.data == null:
						return -1
					else:
						return m.data.id
			)
			
			if button.data.id in deck_monster_ids:
				var index := deck_monster_ids.find(button.data.id)
				monster = Global.player_deck.monster[index]
			else:
				monster = Monster.new()
				monster.data = button.data
			
			selected_monster_changed.emit(monster)
			parent.mode = parent.Mode.STATUS
		)
		
		if i > monster_containers.get_child_count() * HCONTAINER_LIMIT: # コンテナがいっぱいの時
			var container = HBoxContainer.new()
			container.add_theme_constant_override("separation", 20)
			monster_containers.add_child(container) # 新たなコンテナ生成
			
		for container in monster_containers.get_children():
			if container.get_child_count() < HCONTAINER_LIMIT: # 横への表示数の限界でなければ
				container.add_child(button) # 登録
				break


func on_mode_entered():
	for container: HBoxContainer in monster_containers.get_children():
		for child: MonsterIcon in container.get_children():
			child.disabled = false
			child.icon_modulate = 1.0
	
	get_selected_slot_index.emit()
	# 全ての形態の項目を追加
	for i in len(Global.Form.keys()):
		if evolution_preview_button.get_selectable_item(true) < i:
			evolution_preview_button.add_item(Global.form_names[i], i)
	evolution_preview_button.disabled = false
	## 現在選択中のindexに既に存在しているモンスターのデータ
	var selected_index_monster := (
		Global.player_deck.monster[_selected_slot_index].data)
	for monster in Global.player_deck.monster: # 3体のモンスターを順番に処理
		if monster.data != null:
			# モンスターが居ない位置のキャラセレクトをしている時
			# デッキに居るモンスターを選択不可に
			if selected_index_monster == null:
				monster_icon_disabled(monster.data.id)
			
			# すでにモンスターが居る位置のキャラセレクトをしている時
			# その位置以外のデッキに居るモンスターを選択不可に
			elif monster.data.id != selected_index_monster.id:
				monster_icon_disabled(monster.data.id)

## [param id]モンスターのIDを基に、場所を指定して[MonsterIcon]を使用不可に設定する関数
func monster_icon_disabled(id: int) -> void:
	var j := (id - 1) / HCONTAINER_LIMIT ## 行指定
	var i := id - HCONTAINER_LIMIT * j - 1 ## 列指定
	var button: MonsterIcon = monster_containers.get_child(j).get_child(i)
	
	button.disabled = true
	button.icon_modulate = 0.5
	button.mouse_default_cursor_shape = Control.CURSOR_ARROW

## 表示されている全ての[MonsterIcon]の[member MonsterIcon.form]を更新する関数
func update(form: Global.Form) -> void:
	for container in monster_containers.get_children():
		for child: MonsterIcon in container.get_children():
			child.form = form
