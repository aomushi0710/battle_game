extends Control

@onready var statcontainer = get_node("status/ScrollContainer/VBoxContainer")

var monster_data = Global.monster_data
var now_monster_id: int # status関数、同じモンスターかどうかの検出用
const HCONTAINER_LIMIT: int = 7 # モンスターボタンを横に並べられる限界の個数

func _on_戻る_button_up():
	get_tree().change_scene_to_file(Global.deck_scene)


func _on_node_2d_tree_entered() -> void:
	# モンスターの数だけボタンを生成する関数
	for i in range(1, len(monster_data) - 1): # monster_data[i]:Dictionary[Monster]型
		var button = TextureButton.new()
		
		button.name = monster_data[i][0].name
		button.texture_normal = monster_data[i][0].image
		if 2 in monster_data[i]: # 進化可能モンスターならホバーの画像を変える
			button.texture_hover = monster_data[i][2].image
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.mouse_entered.connect(func():status(monster_data[i][0].id))
		button.button_up.connect(func():button_up(monster_data[i][0].id))
		
		if i > $VBoxContainer.get_child_count() * HCONTAINER_LIMIT: # コンテナがいっぱいの時
			var container = HBoxContainer.new()
			$VBoxContainer.add_child(container) # 新たなコンテナ生成
			
		for container in $VBoxContainer.get_children():
			if container.get_child_count() < HCONTAINER_LIMIT: # 横への表示数の限界でなければ
				container.add_child(button) # 登録
				break
	
	for mon in Global.deck1.monster: # 3体のモンスターを順番に処理
		if mon != null:
			# モンスターが居ない位置のキャラセレクトをしている時
			# デッキに居るモンスターを選択不可に
			if Global.deck1.monster[Global.now_picking] == null:
				var id = mon.id
				var j = (id - 1) / HCONTAINER_LIMIT # 行指定
				var i = id - HCONTAINER_LIMIT * j - 1 # 列指定
				$VBoxContainer.get_child(j).get_child(i).disabled = true
				$VBoxContainer.get_child(j).get_child(i).modulate = Color(50, 50, 50)
			else: # すでにモンスターが居る位置のキャラセレクトをしている時
				# その位置以外のデッキに居るモンスターを選択不可に
				if mon.id != Global.deck1.monster[Global.now_picking].id:
					var id = mon.id
					var j = (id - 1) / HCONTAINER_LIMIT # 行指定
					var i = id - HCONTAINER_LIMIT * j - 1 # 列指定
					$VBoxContainer.get_child(j).get_child(i).disabled = true
					$VBoxContainer.get_child(j).get_child(i).modulate = Color(0.5, 0.5, 0.5)


func status(i: int) -> void: # マウスを合わせたモンスターのステータスを表示
	if now_monster_id == i: # 同じモンスターを選んだなら無視
		return
	now_monster_id = i
	for label in statcontainer.get_children(): # 初期化
		label.queue_free()
	## モンスターの各形態情報が入った辞書のkeyのみのリスト
	var monster_keys: Array = monster_data[i].keys()
	monster_keys.sort()
	
	for key in monster_keys:
		var monster: Monster = monster_data[i][key]
		var evolution_text := RichTextLabel.new() # 進化形態のみ追加テキスト
		evolution_text.bbcode_enabled = true
		evolution_text.fit_content = true
		evolution_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		evolution_text.text = "[u]　　　　　　　　 [/u]\n\
		[center]%s[/center]\n[u]ステータス[/u]\n\n" % monster.form_names[monster.form]
		
		statcontainer.add_child(evolution_text)
		for label: RichTextLabel in Global.all_status(monster, 25):
			statcontainer.add_child(label)


func button_up(i: int) -> void: # ボタンが押されたらそのIDのモンスターのセレクトページへ
	Global.selected_monster = i
	get_tree().change_scene_to_file(Global.new_select_scene)
