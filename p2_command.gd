extends VBoxContainer

var index = 1 # deckクラス内におけるモンスターの位置
var select_button = preload("res://技セレクトボタン.tscn")
var monster_dict = Global.player_deck.monster_dict[index]
var monster: Monster = Global.player_deck.monster[index]
var action = Global.player_deck.action[index] # Array[Action]
var chance = Global.player_deck.chance[index] # Array[int]
var act_range = [] # 乱数幅格納
var actions = [] # 現在コマンド選択可能な技を格納 Array[Action]

signal spd
signal command

func _on_player_1_randomize_set(): # 乱数幅設定
	randomize()
	action = Global.player_deck.action[index]
	var sum_range = 0
	for i in len(chance):
		var range = chance[i]
		if i == 0:
			range -= 1
		sum_range += range # ex.1:10% 2:20% 3:30% 4:40%なら、[9,29,59.99]となり、
		act_range.append(sum_range) # 乱数0~9の範囲で1が、10~29で2、30~59で3、60~99で4

func _on_p_1_spd_command(): # 一旦、actionsにappendし、後でまとめてボタンインスタンスを
	for i_ in (4 - len(actions)): # 生成することでindexの位置のズレをなくす。
		var result = randi() % 100 # 0~99の100通りの乱数を生成
		for i in len(act_range): # 技が4つ未満だった場合にも対応
			if result <= act_range[i]: # 乱数に応じて出現する技を決定
				actions.append(action[i])
				break # 対応する技があったら終了
	
	for button in $".".get_children(): # 全てのボタンを削除
			button.queue_free()
	
	for i in len(actions):
		var instance = select_button.instantiate()
		if actions[i].aka != "":
			instance.text = actions[i].aka
		else:
			instance.text = actions[i].name
		instance.action = actions[i]
		instance.button_up.connect(func():select_command(i))
		add_child(instance)

# ボタンの属性アイコンを点滅させるセットアップ関数
func element_icon(button: Button, element_list: Array) -> void:
	if len(element_list) == 1: # 属性が1つだけだった場合
		button.icon = element_list[0].icon
		button.set_process(false)
		button.get_child(0).queue_free()
	else: # 複数の属性を持つ場合
		button.icon = load("res://null.PNG")
		button.get_child(0).scale = Vector2(0.15, 0.15)
		button.get_child(0).position = Vector2(2, 2)
		button.set_process(true) # _processを有効化

func select_command(x :int): # x 押されたボタンの技のindex
	var children = []
	for button in $".".get_children():
		# 以下3行はプレイヤー側のみの処理
		button.disabled = true # 全てのボタンを使用不可に
		if button.get_child_count() == 1: # 複数属性を持つために点滅アイコンを表示している場合
			button.get_child(0).self_modulate = Color(0.5, 0.5, 0.5) # 暗くする
		children.append(button) # 配列に登録
	remove_child(children[x]) # 押されたボタンだけ消す
	# 選ばれた技をactionsから削除しつつ引数指定 真偽値　player:true enemy:false
	command.emit(actions.pop_at(x), monster, true, index)
	spd.emit()

func evolution(id: int) -> void:
	monster = Global.player_deck.monster[index]
	
	var delete_list = [] # 削除したい技のindexを登録するリスト
	for i in len(actions):
		if actions[i].id == id: # 進化技のID 10001 or 10002
			delete_list.append(i)
	
	delete_list.reverse() # indexの並びを逆順にすることで、配列の後ろから要素を削除する
	for i in delete_list:
		actions.remove_at(i)


func _on_p_1_hp_death(): # 死亡時
	for act in $".".get_children():
		act.disabled = true # 全てのボタンを使用不可に
