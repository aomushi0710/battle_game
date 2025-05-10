extends Object

class_name Deck

var monster_dict = [null ,null ,null] # monsterの全ての形態が辞書として登録される
var monster = [null, null, null] # monsterの現在の状態が全て入る
var action: Array[Array] = [[],[],[]]
var evolution = [[],[],[]] # 進化技を登録
var middle_evolution = [[],[],[]] # 中間進化技を登録
var chance = [[],[],[]] # 各技の出現確率を登録
var skill = [0, 0, 0] # スキルパターン(index)を格納
var effect = [{},{},{}] # 各モンスターのエフェクト状態を登録

func evolution_check(deck: Deck):
	for i in range(3):
		var current_monster = deck.monster_dict[i] # Dictionary型
		var current_action = deck.action[i] # Array[Action]型
		
		if len(current_monster) == 3: # 2回進化モンスターの場合
			var middle = current_monster[1] # 第二形態
			var act_list = []
			for act in middle.actions: # 全ての進化技をリストに保存
				act_list.append(act)
			for act in current_action: # 全ての選ばれた技に対して処理
				if act in act_list: # 進化技リストに登録されている技が選ばれていた場合
					deck.middle_evolution[i].append(act) # 中間進化技を登録
		
		if len(current_monster) >= 2: # 1回以上進化できるモンスターの場合
			var evol = current_monster[2] # 以下、同様の処理
			var act_list = []
			for act in evol.actions:
				act_list.append(act)
			for act in current_action:
				if act in act_list:
					deck.evolution[i].append(act)
