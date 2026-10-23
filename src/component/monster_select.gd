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
@export var status_bar: Control
@export var evolution_preview_button: OptionButton

@onready var monster_container := %MonsterContainer as VBoxContainer


func _ready() -> void:
	for i in len(Global.monster_data):
		var button := Global.MONSTER_ICON.instantiate() as MonsterIcon
		
		# HBoxContainerの要素数が最大だった場合、新たにHBoxContainerを作成
		if i > monster_container.get_child_count() * HCONTAINER_LIMIT:
			var container := HBoxContainer.new()
			container.add_theme_constant_override("separation", 20)
			monster_container.add_child(container)
			
		for container in monster_container.get_children():
			if container.get_child_count() < HCONTAINER_LIMIT: # 横への表示数の限界でなければ
				container.add_child(button) # 登録
				break
		
		button.data = Global.monster_data[i]
		button.form = Monster.Form.第一形態
		button.button_up.connect(_on_monster_icon_button_up.bind(button.data))


## 表示されている全ての[MonsterIcon]の[member MonsterIcon.form]を更新する関数
func update(form: Monster.Form) -> void:
	for container in monster_container.get_children() as Array[HBoxContainer]:
		for child in container.get_children() as Array[MonsterIcon]:
			child.form = form

func on_mode_entered():
	for container in monster_container.get_children() as Array[HBoxContainer]:
		for child in container.get_children() as Array[MonsterIcon]:
			child.disabled = false
			child.icon_modulate = 1.0
	
	get_selected_slot_index.emit()
	# 全ての形態の項目を追加
	for i in len(Monster.Form.keys()):
		if evolution_preview_button.get_selectable_item(true) < i:
			evolution_preview_button.add_item(Monster.form_names[i], i)
	evolution_preview_button.disabled = false
	## 現在選択中のindexに既に存在しているモンスターのデータ
	var selected_index_monster: MonsterData = Global.player_deck.monster[_selected_slot_index].data
	for monster in Global.player_deck.monster: # 3体のモンスターを順番に処理
		if monster.data != null:
			# モンスターが居ない位置のキャラセレクトをしている時
			# デッキに居るモンスターを選択不可に
			if not selected_index_monster:
				_monster_icon_disabled(monster.data.id)
			
			# すでにモンスターが居る位置のキャラセレクトをしている時
			# その位置以外のデッキに居るモンスターを選択不可に
			elif monster.data.id != selected_index_monster.id:
				_monster_icon_disabled(monster.data.id)

## TODO マウスカーソルを合わせたモンスターのステータスを表示できるようにする
func _on_monster_icon_mouse_entered() -> void:
	pass

## [MonsterIcon]の[signal BaseButton.button_up]が発行された時、対応するモンスターの設定画面へ遷移させます
func _on_monster_icon_button_up(data: MonsterData) -> void:
	var monster: Monster ## [signal selected_monster_changed]の引数
	## デッキに登録されているモンスターIDの配列。モンスターがいない時は-1。
	var deck_monster_ids: PackedInt32Array
	for mon in Global.player_deck.monster:
		if mon and mon.data and mon.data.id:
			deck_monster_ids.append(mon.data.id)
	
	if data.id in deck_monster_ids:
		var index = deck_monster_ids.find(data.id)
		monster = Global.player_deck.monster[index]
	else:
		monster = Monster.new()
		monster.data = data
	
	selected_monster_changed.emit(monster)
	parent.mode = parent.Mode.STATUS

## [param id]モンスターのIDを基に、場所を指定して[MonsterIcon]を使用不可に設定する関数
func _monster_icon_disabled(id: int) -> void:
	var j := (id - 1) / HCONTAINER_LIMIT ## 行指定
	var i := id - HCONTAINER_LIMIT * j - 1 ## 列指定
	var button: MonsterIcon = monster_container.get_child(j).get_child(i) as MonsterIcon
	
	button.disabled = true
	button.icon_modulate = 0.5
	button.mouse_default_cursor_shape = Control.CURSOR_ARROW
