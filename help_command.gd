extends VBoxContainer

var select_button = preload("res://技セレクトボタン.tscn")
var actions = []
var help_actions = [load("res://action/体当たり.tres"), load("res://action/スタンプ.tres"), \
load("res://action/水しぶき.tres"), load("res://action/光線.tres")]
var children = []
var help_act_range = [39,69,89,99]

signal help_spd

func _on_help_spd_help_command():
	for i_ in (4 - len(actions)): # 生成することでindexの位置のズレをなくす。
		var result = randi() % 100 # 0~99の100通りの乱数を生成
		for i in len(help_act_range): # 技が4つ未満だった場合にも対応
			if result <= help_act_range[i]: # 乱数に応じて出現する技を決定
				actions.append(help_actions[i])
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

func select_command(x): # x 押されたボタンの技のindex
	var children = []
	for button in $".".get_children():
		button.disabled = true # 全てのボタンを使用不可に
		children.append(button) # 配列に登録
	remove_child(children[x]) # 押されたボタンだけ消す
	help_spd.emit()
