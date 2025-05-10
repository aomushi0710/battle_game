extends TextureButton

var index := 2
var monster_dict: Dictionary = Global.deck1.monster_dict[index]
var monster: Monster = Global.deck1.monster[index]
var action: Array = Global.deck1.action[index] # Array[Action]
var evolution: Array = Global.deck1.evolution[index] # Array[Action]
var middle_evolution: Array = Global.deck1.middle_evolution[index] # Array[Action]

signal randomize_set
signal reload_hp(hp: int) # 進化時のデータリロード
signal reload_mp
signal reload_spd
signal reload_action(id: int)

func _on_tree_entered():
	monster.HP = monster.maxHP # バトル開始時のhp及びmp
	monster.MP = int(monster.maxMP / 5)
	ui_setting(monster)
	
	if evolution.is_empty() == false: # 進化技が存在する場合
		var evol_index = [] # evol
		for i in len(action):
			if action[i] in evolution: # 進化技の時
				action[i] = Global.action_data[10002].duplicate() # 進化技を進化Ⅱに置き換える
				action[i].mp = monster_dict[2].cost # 進化に必要なmp量設定
				evol_index.append(i) # 置き換えた技の位置indexを保存
		
		if middle_evolution.is_empty() == false: # さらに中間進化技も存在する場合
			var middle_evol_index = []
			for i in len(action):
				if action[i] in middle_evolution: # 進化技の時
					action[i] = Global.action_data[10001].duplicate() # 進化技を進化Ⅰに置き換える
					action[i].mp = monster_dict[1].cost # 進化に必要なmp量設定
					middle_evol_index.append(i) # 置き換えた技の位置indexを保存
	randomize_set.emit()

func _evolution():
	var evolution_monster: Monster # 進化先となるモンスター
	var id: int # 進化技のID 10001 or 10002
	match monster.form:
		0: # 第一形態
			match len(monster_dict):
				2: # 1回進化モンスター
					evolution_monster = monster_dict[2]
					id = 10002
				3: # 2回進化モンスター
					evolution_monster = monster_dict[1]
					id = 10001
				_:
					print("ERROR:モンスターの形態数が3を越えています")
					return
		1: # 第二形態
			evolution_monster = monster_dict[2]
			id = 10002
		_:
			print("ERROR:このモンスターは進化できません")
			return
	
	var name = monster.name
	var hp = monster.HP # 現在のステータスを記録
	var max_hp = monster.maxHP
	var mp = monster.MP
	var act: int = 0 # 進化技の配列index管理
	
	Global.deck1.monster[index] = evolution_monster.duplicate() # 進化
	monster = Global.deck1.monster[index]
	monster.HP = hp # ステータス引き継ぎ
	monster.MP = mp
	reload_hp.emit(monster.maxHP - max_hp)
	reload_mp.emit()
	reload_spd.emit()
	reload_action.emit(id)
	ui_setting(evolution_monster) # 既にmonsterの中身が置き換わっているのでmonsterでもいいかも
	
	for i: int in len(Global.deck1.action[index]): # 進化技を置き換え
		if Global.deck1.action[index][i].id == id:
			match id:
				10001:
					Global.deck1.action[index][i] = \
					Global.deck1.middle_evolution[index][act]
				10002:
					Global.deck1.action[index][i] = \
					Global.deck1.evolution[index][act]
				_:
					print("ERROR:不明なID")
			act += 1
	
	$"/root/Node2D/log_window/log".text += "[color=red]" + name + \
		" は " + monster.name + " に進化した！[/color]\n"

func ui_setting(monster: Monster) -> void: # monster型の情報を基にUIを表示する
	$".".texture_normal = monster.image # 画像
	$name.text = ""
	for element: Element in monster.element: # 全ての属性を
		$name.text += "[img=50]%s[/img]" % element.icon.resource_path # アイコン化
	$name.text += " [b][i]%s[/i][/b]" % monster.name # 名前
