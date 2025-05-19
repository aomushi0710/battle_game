extends Control

var monster_data = Global.monster_data
const HCONTAINER_LIMIT: int = 7 # モンスターボタンを横に並べられる限界の個数

func _on_戻る_button_up():
	get_tree().change_scene_to_packed(Global.deck_scene)


func _on_node_2d_tree_entered() -> void:
	# モンスターの数だけボタンを生成する関数
	for i in range(1, len(monster_data)): # monster_data[i]:Dictionary[Monster]型
		var button = TextureButton.new()
		
		button.name = monster_data[i][0].name
		button.texture_normal = monster_data[i][0].image
		if 2 in monster_data[i]: # 進化可能モンスターならホバーの画像を変える
			button.texture_hover = monster_data[i][2].image
		
		button.mouse_entered.connect(func():status(monster_data[i][0].id))
		button.button_up.connect(func():button_up(monster_data[i][0].id))
		
		if i > $VBoxContainer.get_child_count() * HCONTAINER_LIMIT: # コンテナがいっぱいの時
			var container = HBoxContainer.new()
			$VBoxContainer.add_child(container) # 新たなコンテナ生成
			
		for container in $VBoxContainer.get_children():
			if container.get_child_count() < HCONTAINER_LIMIT: # 横への表示数の限界でなければ
				container.add_child(button) # 登録
				break
	
	# 既に選ばれているモンスターを選べないように
	for monster in Global.deck1.monster:
		if monster != null:
			if monster.id != Global.deck1.monster[Global.now_picking].id:
				var id = monster.id
				var j = (id - 1) / HCONTAINER_LIMIT # 行指定
				var i = id - HCONTAINER_LIMIT * j - 1 # 列指定
				$VBoxContainer.get_child(j).get_child(i).disabled = true
				$VBoxContainer.get_child(j).get_child(i).modulate = Color(50, 50, 50)


func status(i: int) -> void: # マウスを合わせたモンスターのステータスを表示
	$status/default.text = ""
	var monster = monster_data[i] # dictionary
	var default = monster[0]
	var middle_evolution = null
	var evolution = null
	
	if monster.size() >= 2: # 1回以上進化するモンスター 
		evolution = monster[2]
		if monster.size() == 3: # 2回進化モンスター
			middle_evolution = monster[1]
	
	for form: Monster in [default, middle_evolution, evolution]:
		if form == null: # その形態が存在しなかった場合、次のループへ
			continue
		if form.form == 1:
			$status/default.text += "[center][color=yellow]中間進化後\n[u]ステータス[/u][/color][/center]\n"
		elif form.form == 2:
			$status/default.text += "[center][color=red]進化後\n[u]ステータス[/u][/color][/center]\n"
		
		$status/default.text += Global.status_text(form,20)

func button_up(i: int) -> void: # ボタンが押されたらそのIDのモンスターのセレクトページへ
	Global.selected_monster = i
	get_tree().change_scene_to_packed(Global.select_scene)
